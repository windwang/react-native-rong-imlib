package io.rong.imlib.ipc;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.net.Uri;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.util.Base64;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.UiThreadUtil;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.modules.core.RCTNativeAppEventEmitter;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Date;
import java.util.List;

import io.rong.imlib.IRongCallback;
import io.rong.imlib.RongIMClient;
import io.rong.imlib.model.Conversation;
import io.rong.imlib.model.Message;
import io.rong.imlib.model.MessageContent;
import io.rong.imlib.model.UserInfo;
import io.rong.push.RongPushClient;

/**
 * Created by tdzl2003 on 3/31/16.
 */
public class IMLibModule extends ReactContextBaseJavaModule implements RongIMClient.OnReceiveMessageListener, RongIMClient.ConnectionStatusListener {

  static boolean isIMClientInited = false;
  public static ReactApplicationContext context;

  public IMLibModule(ReactApplicationContext reactContext) {
    super(reactContext);
    context = reactContext;


    if (!isIMClientInited) {
      isIMClientInited = true;

      ApplicationInfo appInfo = null;
      try {
        appInfo = reactContext.getPackageManager().getApplicationInfo(reactContext.getPackageName(), PackageManager.GET_META_DATA);

        if (appInfo != null) {
          Bundle bundle = appInfo.metaData;
          String miKey=bundle.getString("MI_APP_KEY");
          String miId=bundle.getString("MI_APP_ID");
          if(miKey!=null&&miId!=null){
            RongPushClient.registerMiPush(reactContext.getApplicationContext(), miId,  miKey);
          }
        }
      } catch (PackageManager.NameNotFoundException e) {
        e.printStackTrace();
      }


      RongIMClient.init(reactContext.getApplicationContext());
    }
  }

  @Override
  public String getName() {
    return "RCTRongIMLib";
  }

  @Override
  public void initialize() {
    RongIMClient.setOnReceiveMessageListener(this);
    RongIMClient.setConnectionStatusListener(this);
  }

  @Override
  public void onCatalystInstanceDestroy() {
    RongIMClient.setOnReceiveMessageListener(null);
    RongIMClient.getInstance().disconnect();
  }

  private void sendDeviceEvent(String type, Object arg) {
    ReactContext context = this.getReactApplicationContext();
    context.getJSModule(RCTNativeAppEventEmitter.class)
      .emit(type, arg);

  }

  @Override
  public boolean onReceived(Message message, int i) {
    sendDeviceEvent("rongIMMsgRecved", Utils.convertMessage(message));
    return true;
  }

  RongIMClient client = null;

  UserInfo userInfo = null;

  /**
   * 设置当前的userinfo
   *
   * @param map
   * @param promise
   */
  @ReactMethod
  public void setCurrentUserInfo(final ReadableMap map, final Promise promise) {
    this.userInfo = Utils.convertUserInfo(map);
    promise.resolve(true);

  }

  @ReactMethod
  public void connect(String token, final Promise promise) {
    if (client != null) {
      promise.reject("AlreadyLogined", "Is already logined.");
      return;
    }
    client = RongIMClient.connect(token, new RongIMClient.ConnectCallback() {
      /**
       * Token 错误，在线上环境下主要是因为 Token 已经过期，您需要向 App Server 重新请求一个新的 Token
       */
      @Override
      public void onTokenIncorrect() {
        promise.reject("tokenIncorrect", "Incorrect token provided.");
      }

      /**
       * 连接融云成功
       * @param userid 当前 token
       */
      @Override
      public void onSuccess(String userid) {
        promise.resolve(userid);
      }

      /**
       * 连接融云失败
       * @param errorCode 错误码，可到官网 查看错误码对应的注释
       */
      @Override
      public void onError(RongIMClient.ErrorCode errorCode) {
        promise.reject("" + errorCode.getValue(), errorCode.getMessage());
      }
    });
  }

  @ReactMethod
  public void getConversationList(final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.getConversationList(new DefaultResultCallBack<List<Conversation>>(promise) {
      @Override
      public void onSuccess(List<Conversation> conversations) {
        promise.resolve(Utils.convertConversationList(conversations));
      }
    });
  }

  @ReactMethod
  public void getConversation(String conversationType, String targetId, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.getConversation(Conversation.ConversationType.valueOf(conversationType.toUpperCase()), targetId, new DefaultResultCallBack<Conversation>(promise) {
      @Override
      public void onSuccess(Conversation conversation) {
        promise.resolve(Utils.convertConversation(conversation));
      }
    });
  }

  @ReactMethod
  public void updateConversation(String conversationType, String targetId, String title, String portrait, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.updateConversationInfo(Conversation.ConversationType.valueOf(conversationType.toUpperCase()), targetId, title, portrait, new DefaultResultCallBack<Boolean>(promise));
  }

  @ReactMethod
  public void clearMessages(String conversationType, String targetId, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.clearMessages(Conversation.ConversationType.valueOf(conversationType.toUpperCase()), targetId, new DefaultResultCallBack<Boolean>(promise));
  }

  @ReactMethod
  public void logout(final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.logout();
    client = null;
    promise.resolve(null);


  }

  @ReactMethod
  public void disconnect(final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.disconnect();
    promise.resolve(null);
  }


  @ReactMethod
  public void getLatestMessages(String type, String targetId, int count, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.getLatestMessages(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, count, new MessagesCallback(promise));
  }


  @ReactMethod
  public void getHistoryMessages(String type, String targetId, String objectName, int oldestMessageId, int count, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    if (objectName == null || objectName.isEmpty()) {
      client.getHistoryMessages(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, oldestMessageId, count, new MessagesCallback(promise));
    } else {
      client.getHistoryMessages(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, objectName, oldestMessageId, count, new MessagesCallback(promise));
    }


  }

  private void attachUserInfo(MessageContent messageContent) {
    if (this.userInfo == null) return;
    messageContent.setUserInfo(userInfo);
  }


  @ReactMethod
  public void sendMessage(final String type, final String targetId, final ReadableMap map, final String pushContent, final String pushData, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    if ("image".equals(map.getString("type"))) {
      sendImageMessage(type, targetId, map, pushContent, pushData, promise);
      return;
    }
    if ("location".equals(map.getString("type"))) {
      setLocationMessage(type, targetId, map, pushContent, pushData, promise);
      return;
    }
    MessageContent messageContent = Utils.convertToMessageContent(map);
    attachUserInfo(messageContent);
    client.sendMessage(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, messageContent, pushContent, pushData, new RongIMClient.SendMessageCallback() {
      @Override
      public void onError(Integer messageId, RongIMClient.ErrorCode e) {
        WritableMap ret = Arguments.createMap();
        ret.putInt("messageId", messageId);
        ret.putInt("errCode", e.getValue());
        ret.putString("errMsg", e.getMessage());
        sendDeviceEvent("msgSendFailed", ret);
      }

      @Override
      public void onSuccess(Integer messageId) {
        sendDeviceEvent("msgSendOk", messageId);

      }

    }, new MessageCallBack(promise));
  }

  private void setLocationMessage(String type, String targetId, ReadableMap map, final String pushContent, final String pushData, final Promise promise) {
    MessageContent locationContent = Utils.convertToMessageContent(map);
    attachUserInfo(locationContent);
    Message locationMessage = Message.obtain(targetId, Conversation.ConversationType.valueOf(type.toUpperCase()), locationContent);
    client.sendLocationMessage(locationMessage, pushContent, pushData, new IRongCallback.ISendMessageCallback() {
      @Override
      public void onAttached(Message message) {
        promise.resolve(Utils.convertMessage(message));
      }

      @Override
      public void onError(Message message, RongIMClient.ErrorCode e) {
        WritableMap ret = Arguments.createMap();
        ret.putInt("messageId", message.getMessageId());
        ret.putInt("errCode", e.getValue());
        ret.putString("errMsg", e.getMessage());
        sendDeviceEvent("msgSendFailed", ret);
      }

      @Override
      public void onSuccess(Message message) {
        sendDeviceEvent("msgSendOk", message.getMessageId());
      }
    });
  }

  private void sendImageMessage(final String type, final String targetId, ReadableMap map, final String pushContent, final String pushData, final Promise promise) {
    Utils.getImage(Uri.parse(map.getString("imageUrl")), null, new Utils.ImageCallback() {

      @Override
      public void invoke(@Nullable Bitmap bitmap) {
        if (bitmap == null) {
          promise.reject("loadImageFailed", "Cannot open image uri ");
          return;
        }
        MessageContent content;
        try {
          content = Utils.convertImageMessageContent(getReactApplicationContext(), bitmap);
        } catch (Throwable e) {
          promise.reject("cacheImageFailed", e);
          return;
        }
        attachUserInfo(content);
        client.sendImageMessage(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, content, pushContent, pushData, new RongIMClient.SendImageMessageCallback() {

          @Override
          public void onAttached(Message message) {
            promise.resolve(Utils.convertMessage(message));
          }

          @Override
          public void onError(Message message, RongIMClient.ErrorCode e) {
            WritableMap ret = Arguments.createMap();
            ret.putInt("messageId", message.getMessageId());
            ret.putInt("errCode", e.getValue());
            ret.putString("errMsg", e.getMessage());
            sendDeviceEvent("msgSendFailed", ret);
          }

          @Override
          public void onSuccess(Message message) {
            sendDeviceEvent("msgSendOk", message.getMessageId());
          }

          @Override
          public void onProgress(Message message, int i) {

          }
        });
      }
    });
  }

  @ReactMethod
  public void insertMessage(String type, String targetId, String senderId, ReadableMap map, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.insertMessage(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, senderId, Utils.convertToMessageContent(map),
      new MessageCallBack(promise));
  }

  @ReactMethod
  public void clearMessageUnreadStatus(String type, String targetId, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.clearMessagesUnreadStatus(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, new DefaultResultCallBack<Boolean>(promise));
  }


  @ReactMethod
  public void setMessageReceivedStatus(int messageId, int receivedStatus, final Promise promise) {
    if (client == null) {
      promise.reject("NotLogined", "Must call connect first.");
      return;
    }
    client.setMessageReceivedStatus(messageId, new Message.ReceivedStatus(receivedStatus), new DefaultResultCallBack<Boolean>(promise));
  }

  private MediaRecorder recorder;
  private Promise recordPromise;

  private File recordTarget = new File(this.getReactApplicationContext().getFilesDir(), "imlibrecord.amr");

  private long startTime;

  @ReactMethod
  public void startRecordVoice(Promise promise) {
    if (recorder != null) {
      cancelRecordVoice();
      return;
    }
    startTime = new Date().getTime();
    recorder = new MediaRecorder();// new出MediaRecorder对象
    // 设置MediaRecorder的音频源为麦克风
    recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
    // 设置MediaRecorder录制的音频格式
    recorder.setOutputFormat(MediaRecorder.OutputFormat.AMR_NB);
    // 设置MediaRecorder录制音频的编码为amr.
    recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);

    recorder.setAudioChannels(1);
    recorder.setAudioSamplingRate(8000);

    recorder.setOnErrorListener(new MediaRecorder.OnErrorListener() {
      @Override
      public void onError(MediaRecorder mr, int what, int extra) {
        Log.d("MediaRecord", "OnError: " + what + "" + extra);
      }
    });

    recorder.setOnInfoListener(new MediaRecorder.OnInfoListener() {
      @Override
      public void onInfo(MediaRecorder mr, int what, int extra) {
        Log.d("MediaRecord", "OnInfo: " + what + "" + extra);
      }
    });

    recorder.setOutputFile(recordTarget.toString());

    try {
      recorder.prepare();
    } catch (IOException e) {
      recorder.release();
      recorder = null;
      promise.reject(e);
      return;
    }
    recorder.start();
    recordPromise = promise;
  }

  @ReactMethod
  public void cancelRecordVoice() {
    if (recorder == null) {
      return;
    }
    recorder.stop();
    recorder.release();
    recorder = null;
    recordPromise.reject("Canceled", "Record was canceled by user.");
    recordPromise = null;
  }

  @ReactMethod
  public void finishRecordVoice() {
    if (recorder == null) {
      return;
    }
    recorder.stop();
    recorder.release();
    recorder = null;
    FileInputStream inputFile = null;
    try {
      WritableMap ret = Arguments.createMap();

      inputFile = new FileInputStream(recordTarget);
      byte[] buffer = new byte[(int) recordTarget.length()];
      inputFile.read(buffer);
      inputFile.close();
      ret.putString("type", "voice");
      ret.putString("base64", Base64.encodeToString(buffer, Base64.DEFAULT));
      ret.putString("uri", Uri.fromFile(recordTarget).toString());
      ret.putInt("duration", (int) (new Date().getTime() - startTime));
      recordPromise.resolve(ret);
    } catch (IOException e) {
      recordPromise.reject(e);
      e.printStackTrace();
    }
    recordPromise = null;
  }

  private MediaPlayer player;
  private Promise playerPromise;

  @ReactMethod
  public void startPlayVoice(ReadableMap map, Promise promise) {
    if (player != null) {
      this.stopPlayVoice();
    }

    String strUri = map.getString("uri");
    player = MediaPlayer.create(this.getReactApplicationContext(), Uri.parse(strUri));
    playerPromise = promise;
    player.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
      @Override
      public void onCompletion(MediaPlayer mp) {
        onPlayComplete(mp);
      }
    });
    player.start();
  }

  private void onPlayComplete(MediaPlayer mp) {
    if (player == mp) {
      playerPromise.resolve(null);
      playerPromise = null;
      player.release();
      player = null;
    }
  }

  @ReactMethod
  public void stopPlayVoice() {
    if (player != null) {
      playerPromise.reject("Canceled", "Record was canceled by user.");
      playerPromise = null;
      player.stop();
      player.release();
      player = null;
    }
  }

  @Override
  public void onChanged(ConnectionStatus connectionStatus) {
    WritableMap map = Arguments.createMap();
    map.putInt("code", connectionStatus.getValue());
    map.putString("message", connectionStatus.getMessage());
    this.sendDeviceEvent("rongIMConnectionStatus", map);
  }

  class DefaultResultCallBack<T> extends RongIMClient.ResultCallback<T> {
    Promise promise;

    public DefaultResultCallBack(final Promise promise) {
      this.promise = promise;
    }

    @Override
    public void onSuccess(T result) {
      promise.resolve(result);
    }

    @Override
    public void onError(RongIMClient.ErrorCode errorCode) {
      promise.reject("" + errorCode.getValue(), errorCode.getMessage());
    }
  }

  class MessageCallBack extends DefaultResultCallBack<Message> {

    public MessageCallBack(final Promise promise) {
      super(promise);
    }

    @Override
    public void onSuccess(Message message) {
      promise.resolve(Utils.convertMessage(message));
    }

  }

  class MessagesCallback extends DefaultResultCallBack<List<Message>> {

    public MessagesCallback(final Promise promise) {
      super(promise);
    }

    @Override
    public void onSuccess(List<Message> messages) {
      promise.resolve(Utils.convertMessageList(messages));
    }

  }
}
