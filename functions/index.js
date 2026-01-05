const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Inicializa o Firebase Admin
admin.initializeApp();

const dbDefault = admin.firestore();
const messaging = admin.messaging();

// Import v2 functions
const { onCall } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');

// Funções auxiliares para notificações
function gerarTituloNotificacao(doc) {
  if (doc.nomeDe) {
    return doc.nomeDe;
  }
  return 'Nova mensagem';
}

function gerarResumoNotificacao(doc) {
  if (doc.type === 0) {
    return doc.content || 'Mensagem';
  } else if (doc.type === 1) {
    return '📷 Imagem';
  } else if (doc.type === 2) {
    return '🎤 Áudio';
  }
  return 'Nova mensagem';
}

// ============= FUNÇÕES CALLABLE =============

exports.marcarEmailVerificado = onCall(async (request) => {
  const { userId } = request.data;
  try {
    const userRecord = await admin.auth().updateUser(userId, {
      emailVerified: true,
    });
    console.log('Successfully updated user', userRecord.toJSON());
    return { resposta: 'Atualizado com sucesso!', data: userRecord.toJSON() };
  } catch (error) {
    console.log('Error updating user:', error);
    throw new functions.https.HttpsError('internal', 'Erro ao atualizar!', error);
  }
});

exports.atualizarSenhaUsuario = onCall(async (request) => {
  const { userId, password } = request.data;
  try {
    const userRecord = await admin.auth().updateUser(userId, {
      password: password,
    });
    console.log('Successfully updated user', userRecord.toJSON());
    return { resposta: 'Atualizado com sucesso!', data: userRecord.toJSON() };
  } catch (error) {
    console.log('Error updating user:', error);
    throw new functions.https.HttpsError('internal', 'Erro ao atualizar!', error);
  }
});

exports.atualizarEmailUsuario = onCall(async (request) => {
  const { userId, email } = request.data;
  try {
    const userRecord = await admin.auth().updateUser(userId, {
      email: email,
    });
    console.log('Successfully updated user', userRecord.toJSON());
    return { resposta: 'Atualizado com sucesso!', data: userRecord.toJSON() };
  } catch (error) {
    console.log('Error updating user:', error);
    throw new functions.https.HttpsError('internal', 'Erro ao atualizar!', error);
  }
});

// ============= FUNÇÃO HTTP REQUEST =============

exports.timestamp = functions.https.onRequest({
  cors: true,
}, (request, response) => {
  const token_server = 'key_safy_menu_25262728';
  const token_receive = request.query['token'];

  if (token_server === token_receive) {
    response.status(200).send({ timestamp: Date.now() });
  } else if (!token_receive) {
    response.status(401).send('Token não enviado!\nEnvie o token como json { "token" : "token_key" }.');
  } else {
    response.status(403).send('Não autorizado! O token não corresponde ao token de requisição..');
  }
});

// ============= TRIGGERS FIRESTORE =============

exports.sendNotification = onDocumentCreated({
  document: 'usuarios/{userid}/chat/{mensagem}',
  region: 'southamerica-east1',
}, async (event) => {
  try {
    console.log('🔔 [SEND_NOTIFICATION] Iniciando envio de notificação...');

    const doc = event.data.data();
    const idTo = doc.idTo;
    const useridChat = event.params.userid;

    console.log(`📋 [SEND_NOTIFICATION] UserID: ${useridChat}, idTo: ${idTo}, idFrom: ${doc.idFrom}`);

    if (!idTo) {
      console.log('⚠️ [SEND_NOTIFICATION] idTo não definido, ignorando notificação');
      return;
    }

    const urlImagem = doc.urlImagem;
    const tagNotification = `${useridChat}_${Date.now()}`;
    const idFrom = doc.idFrom;

    let tokensNotificacao = [];

    // Busca tokens de notificação
    if (useridChat == idFrom) {
      console.log('👤 [SEND_NOTIFICATION] Buscando token do administrador...');
      const snapshot = await dbDefault.collection('administradores').doc(idTo).get();
      if (snapshot.exists && snapshot.data()['pushToken']) {
        tokensNotificacao.push(snapshot.data()['pushToken']);
        console.log(`✅ [SEND_NOTIFICATION] Token do administrador encontrado`);
      } else {
        console.log('❌ [SEND_NOTIFICATION] Token do administrador não encontrado');
      }
    } else {
      console.log('🏪 [SEND_NOTIFICATION] Buscando tokens da loja...');
      const snapshot = await dbDefault.collection('lojas').doc(useridChat).get();
      if (snapshot.exists && snapshot.data()['fcmTokens']) {
        tokensNotificacao = snapshot.data()['fcmTokens'];
        console.log(`✅ [SEND_NOTIFICATION] ${tokensNotificacao.length} token(s) encontrado(s) na loja`);
      } else {
        console.log('❌ [SEND_NOTIFICATION] Tokens da loja não encontrados');
      }
    }

    if (tokensNotificacao.length === 0) {
      console.log('⚠️ [SEND_NOTIFICATION] Nenhum token disponível para envio');
      return;
    }

    // Envia notificações
    console.log(`📤 [SEND_NOTIFICATION] Enviando para ${tokensNotificacao.length} token(s)...`);

    const promises = tokensNotificacao.map(async (token, index) => {
      try {
        const message = {
          token: token,
          notification: {
            title: gerarTituloNotificacao(doc),
            body: gerarResumoNotificacao(doc),
            image: urlImagem,
          },
          data: {
            payload: 'chat',
            parametro: useridChat,
            tag: tagNotification,
          },
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'chat',
              notification_priority: 'PRIORITY_HIGH',
              tag: tagNotification,
            },
          },
          apns: {
            headers: {
              'apns-collapse-id': tagNotification,
              'thread-id': tagNotification,
            },
          },
        };

        const response = await messaging.send(message);
        console.log(`✅ [SEND_NOTIFICATION] Token ${index + 1}/${tokensNotificacao.length} - Sucesso:`, response);
        return { success: true, response };
      } catch (error) {
        console.error(`❌ [SEND_NOTIFICATION] Token ${index + 1}/${tokensNotificacao.length} - Erro:`, {
          code: error.code,
          message: error.message,
          token: token.substring(0, 20) + '...',
        });
        return { success: false, error };
      }
    });

    const results = await Promise.allSettled(promises);
    const successCount = results.filter(r => r.status === 'fulfilled' && r.value.success).length;
    const failCount = results.length - successCount;

    console.log(`📊 [SEND_NOTIFICATION] Resultado: ${successCount} enviadas, ${failCount} falhas`);

  } catch (error) {
    console.error('❌ [SEND_NOTIFICATION] Erro fatal na função:', {
      message: error.message,
      stack: error.stack,
    });
  }
});

exports.updateChat = onDocumentUpdated({
  document: 'chat/{mensagem}',
  region: 'southamerica-east1',
}, async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (afterData.idTransferencia != null) {
    if (beforeData.idAtendente != afterData.idAtendente) {
      const snapshotAtendente = await dbDefault.collection('administradores').doc(beforeData.idAtendente).collection('perfil').doc('perfilUsuario').get();

      const userId = afterData.idUsuario;
      const nomeAtendente = snapshotAtendente.data().nome;
      const tagNotification = `${userId}_${Date.now()}`;

      const tokensNotificacao = [];

      const snapshot = await dbDefault.collection('administradores').doc(afterData.idAtendente).get();
      tokensNotificacao.push(`${snapshot.data()['pushToken']}`);

      tokensNotificacao.forEach(token => {
        const message = {
          token: token,
          notification: {
            title: `${nomeAtendente} te enviou um atendimento`,
            body: 'Dê continuidade ao atendimento.',
            image: 'https://firebasestorage.googleapis.com/v0/b/atual-controle-356a9.appspot.com/o/atualControle%2Fnova_mensagem.png?alt=media&token=d0ab54f4-e4ba-4c89-99ff-fae3817c650a',
          },
          data: {
            payload: 'new_chat',
            parametro: userId,
            tag: tagNotification,
          },
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'new_chat',
              notification_priority: 'PRIORITY_HIGH',
              tag: tagNotification,
            },
          },
          apns: {
            headers: {
              'apns-collapse-id': tagNotification,
            },
          },
        };
        admin.messaging().send(message)
          .then((response) => {
            console.log('Mensagem enviada com sucesso:', response);
          })
          .catch((error) => {
            console.log('Erro ao enviar mensagem:', error);
          });
      });
    }
  }
});

exports.newChat = onDocumentCreated({
  document: 'chat/{mensagem}',
  region: 'southamerica-east1',
}, async (event) => {
  const doc = event.data.data();

  if (doc.idAtendente == null) {
    const topic = 'administradores';
    const userId = doc.idUsuario;
    const tagNotification = `${userId}_${Date.now()}`;

    const message = {
      topic: topic,
      notification: {
        title: 'Chamado na área!',
        body: 'Alguém tá te esperando no chat pra ser atendido. 😊',
        // image: 'https://firebasestorage.googleapis.com/v0/b/atual-controle-356a9.appspot.com/o/atualControle%2Fnova_mensagem.png?alt=media&token=792ad0c0-2c7d-4d57-98b8-e0a99a942d3f'
      },
      data: {
        payload: 'newChat',
        parametro: userId,
        tag: tagNotification,
      },
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: 'new_chat',
          notification_priority: 'PRIORITY_HIGH',
          tag: tagNotification,
        },
      },
      apns: {
        headers: {
          'apns-collapse-id': tagNotification,
        },
      },
    };
    admin.messaging().send(message)
      .then((response) => {
        console.log('Mensagem enviada com sucesso:', response);
      })
      .catch((error) => {
        console.log('Erro ao enviar mensagem:', error);
      });
  }
});
