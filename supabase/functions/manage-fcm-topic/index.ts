import admin from 'npm:firebase-admin@12.1.1';

// Initialize Firebase Admin App
// Ensure FIREBASE_SERVICE_ACCOUNT is set in Supabase Secrets
const serviceAccountKey = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
if (!serviceAccountKey) {
  console.error("Missing FIREBASE_SERVICE_ACCOUNT secret");
} else {
  try {
    const serviceAccount = JSON.parse(serviceAccountKey);
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    }
  } catch (error) {
    console.error("Error parsing FIREBASE_SERVICE_ACCOUNT or initializing Firebase Admin:", error);
  }
}

Deno.serve(async (req: Request) => {
  // Verificación simple de secret para evitar requests no autorizados si es trigger remoto
  // En supabase webhooks por defecto se envían requests autenticados o con un Authorization Header, 
  // o podemos chequear el payload.
  
  try {
    const payload = await req.json();
    const { type, old_record, record } = payload;
    
    console.log(`Received webhook type: ${type}`);

    // If Firebase isn't initialized, we can't do anything
    if (!admin.apps.length) {
      return new Response(JSON.stringify({ error: "Firebase Admin not initialized. Check Secrets." }), { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const messaging = admin.messaging();

    if (type === 'DELETE') {
      const oldToken = old_record?.fcm_token;
      const oldBarrio = old_record?.barrio_id;
      if (oldToken && oldBarrio) {
         try {
           await messaging.unsubscribeFromTopic(oldToken, `barrio_${oldBarrio}`);
           console.log(`[DELETE] Unsubscribed token from barrio_${oldBarrio}`);
         } catch(e) {
           console.error('[DELETE] Error unsubscribing:', e);
         }
      }
      return new Response(JSON.stringify({ success: true }), { status: 200 });
    }

    const oldToken = old_record?.fcm_token;
    const newToken = record?.fcm_token;
    const oldBarrio = old_record?.barrio_id;
    const newBarrio = record?.barrio_id;
    
    // We only need to act if fcm_token or barrio_id has changed
    const hasChanged = oldToken !== newToken || oldBarrio !== newBarrio;
    
    if (type === 'INSERT') {
      if (newToken && newBarrio) {
        try {
          await messaging.subscribeToTopic(newToken, `barrio_${newBarrio}`);
          console.log(`[INSERT] Subscribed token to barrio_${newBarrio}`);
        } catch (e) {
          console.error('[INSERT] Error subscribing:', e);
        }
      }
    } else if (type === 'UPDATE' && hasChanged) {
      // Unsubscribe old topic if standard changes happened
      if (oldToken && oldBarrio) {
        try {
          await messaging.unsubscribeFromTopic(oldToken, `barrio_${oldBarrio}`);
          console.log(`[UPDATE] Unsubscribed old token from barrio_${oldBarrio}`);
        } catch (e) {
          console.error('[UPDATE] Error unsubscribing:', e);
        }
      }

      // Subscribe to new topic
      if (newToken && newBarrio) {
        try {
          await messaging.subscribeToTopic(newToken, `barrio_${newBarrio}`);
          console.log(`[UPDATE] Subscribed new token to barrio_${newBarrio}`);
        } catch (e) {
          console.error('[UPDATE] Error subscribing:', e);
        }
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error("Webhook processing error:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }
});
