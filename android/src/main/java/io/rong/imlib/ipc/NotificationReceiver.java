package io.rong.imlib.ipc;

import android.app.ActivityManager;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.facebook.react.ReactApplication;
import com.facebook.react.ReactInstanceManager;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;

import io.rong.push.notification.PushMessageReceiver;
import io.rong.push.notification.PushNotificationMessage;

import static android.content.Context.ACTIVITY_SERVICE;
import static com.facebook.react.common.ApplicationHolder.getApplication;

/**
 * Created by wwm on 2016-11-07.
 */

public class NotificationReceiver extends PushMessageReceiver {

  @Override
  public boolean onNotificationMessageArrived(Context context, PushNotificationMessage pushNotificationMessage) {
    Log.e("===RongPushMessage", pushNotificationMessage.getPushContent());


//    Bundle bundle=new Bundle();
//
//
//    sendEvent("remoteNotificationReceived", params);
//
//    // We need to run this on the main thread, as the React code assumes that is true.
//    // Namely, DevServerHelper constructs a Handler() without a Looper, which triggers:
//    // "Can't create handler inside thread that has not called Looper.prepare()"
//    Handler handler = new Handler(Looper.getMainLooper());
//    handler.post(new Runnable() {
//      public void run() {
//        // Construct and load our normal React JS code bundle
//        ReactInstanceManager mReactInstanceManager = ((ReactApplication) getApplication()).getReactNativeHost().getReactInstanceManager();
//        ReactContext context = mReactInstanceManager.getCurrentReactContext();
//        // If it's constructed, send a notification
//        if (context != null) {
//          handleRemotePushNotification((ReactApplicationContext) context, bundle);
//        } else {
//          // Otherwise wait for construction, then send the notification
//          mReactInstanceManager.addReactInstanceEventListener(new ReactInstanceManager.ReactInstanceEventListener() {
//            public void onReactContextInitialized(ReactContext context) {
//              handleRemotePushNotification((ReactApplicationContext) context, bundle);
//            }
//          });
//          if (!mReactInstanceManager.hasStartedCreatingInitialContext()) {
//            // Construct it in the background
//            mReactInstanceManager.createReactContextInBackground();
//          }
//        }
//      }
//    });


    return false;
  }

  /**
   * {"conversationType":"SYSTEM","isFromPush":"true","objectName":"RC:TxtMsg","pushContent":"vvv","pushData":"vvv","pushId":"","pushTitle":"","receivedTime":1487911699546,"senderId":"4369","senderName":"4369","targetId":"4369","targetUserName":"4369"}
   * {"conversationType":"SYSTEM","isFromPush":"true","objectName":"RC:TxtMsg","pushContent":"vvv","pushData":"vvv","pushId":"","pushTitle":"","receivedTime":1487911699546,"senderId":"4369","senderName":"4369","targetId":"4369","targetUserName":"4369"}
   * <p>
   * { NativeMap: {"dataJSON":"{\"conversationType\":\"SYSTEM\",\"isFromPush\":\"true\",\"objectName\":\"RC:ImgMsg\",\"pushContent\":\"4369:[图片]\",\"pushData\":\"\",\"pushId\":\"\",\"pushTitle\":\"\",\"receivedTime\":1487912084741,\"senderId\":\"4369\",\"senderName\":\"4369\",\"targetId\":\"4369\",\"targetUserName\":\"4369\"}"} }
   *
   * @param context
   * @param pushNotificationMessage
   * @return
   */
  @Override
  public boolean onNotificationMessageClicked(Context context, PushNotificationMessage pushNotificationMessage) {
    Log.e("RongPushMessage Clicked", pushNotificationMessage.getPushContent());
    ReactApplication applictionContext = (ReactApplication) context.getApplicationContext();


    sendEvent(applictionContext, "remoteNotificationReceived", pushNotificationMessage);
    return true;
  }

  void sendEvent(final ReactApplication application, final String eventName, final PushNotificationMessage pushNotificationMessage) {
    Handler handler = new Handler(Looper.getMainLooper());
    handler.post(new Runnable() {
      public void run() {
        // Construct and load our normal React JS code bundle

        ReactInstanceManager mReactInstanceManager = application.getReactNativeHost().getReactInstanceManager();
        ReactContext context = mReactInstanceManager.getCurrentReactContext();

        // If it's constructed, send a notification
        if (context != null) {
          handleRemotePushNotification(context, eventName, pushNotificationMessage);

        } else {
          // Otherwise wait for construction, then send the notification
          mReactInstanceManager.addReactInstanceEventListener(new ReactInstanceManager.ReactInstanceEventListener() {
            public void onReactContextInitialized(ReactContext context) {
              handleRemotePushNotification(context, eventName, pushNotificationMessage);
            }
          });
          if (!mReactInstanceManager.hasStartedCreatingInitialContext()) {
            // Construct it in the background
            mReactInstanceManager.createReactContextInBackground();
          }
        }
      }
    });
//    if (IMLibModule.context.hasActiveCatalystInstance()) {
//      IMLibModule.context
//        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
//        .emit(eventName, params);
//    }
  }

  private void handleRemotePushNotification(ReactContext context, final String eventName, final PushNotificationMessage pushNotificationMessage) {


    Gson gsonBuilder = new Gson();

    String bundleString = gsonBuilder.toJson(pushNotificationMessage);

    WritableMap params = Arguments.createMap();
    params.putString("dataJSON", bundleString);

    context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
      .emit(eventName, params);
    if (!isApplicationInForeground()) {
      Intent intent = new Intent(context, getMainActivityClass(context));

      intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
      Bundle bundle = jsonStringToBundle(bundleString);
      bundle.putBoolean("userInteraction", true);
      intent.putExtra("notification", bundle);
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
      context.startActivity(intent);
    }

  }

  public static Bundle jsonStringToBundle(String jsonString) {
    try {
      JSONObject jsonObject = toJsonObject(jsonString);
      return jsonToBundle(jsonObject);
    } catch (JSONException ignored) {

    }
    return null;
  }

  public static JSONObject toJsonObject(String jsonString) throws JSONException {
    return new JSONObject(jsonString);
  }

  public static Bundle jsonToBundle(JSONObject jsonObject) throws JSONException {
    Bundle bundle = new Bundle();
    Iterator iter = jsonObject.keys();
    while (iter.hasNext()) {
      String key = (String) iter.next();
      String value = jsonObject.getString(key);
      bundle.putString(key, value);
    }
    return bundle;
  }

  public Class getMainActivityClass(ReactContext context) {
    String packageName = context.getPackageName();
    Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
    String className = launchIntent.getComponent().getClassName();
    try {
      return Class.forName(className);
    } catch (ClassNotFoundException e) {
      e.printStackTrace();
      return null;
    }
  }

  private boolean isApplicationInForeground() {
    ActivityManager activityManager = (ActivityManager) getApplication().getSystemService(ACTIVITY_SERVICE);
    List<ActivityManager.RunningAppProcessInfo> processInfos = activityManager.getRunningAppProcesses();
    for (ActivityManager.RunningAppProcessInfo processInfo : processInfos) {
      if (processInfo.processName.equals(getApplication().getPackageName())) {
        if (processInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
          for (String d : processInfo.pkgList) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
