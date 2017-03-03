-keep class io.rong.imlib.ipc.NotificationReceiver {*;}
-dontwarn com.xiaomi.mipush.sdk.**
-keep public class com.xiaomi.mipush.sdk.* {*; }
-keep public class com.google.android.gms.gcm.**
-dontwarn io.rong.push.**
 -dontnote com.xiaomi.**
-dontnote com.google.android.gms.gcm.**
 -dontnote io.rong.**