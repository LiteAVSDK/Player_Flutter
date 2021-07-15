package com.example.super_player;

import android.app.Activity;
import android.util.SparseArray;

import androidx.annotation.NonNull;

import com.tencent.rtmp.TXLiveBase;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;

/** SuperPlayerPlugin */
public class SuperPlayerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private FlutterPluginBinding mFlutterPluginBinding;
  private ActivityPluginBinding mActivityPluginBinding;
  private SparseArray<FTXBasePlayer> mPlayers;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    mFlutterPluginBinding = flutterPluginBinding;
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "super_player");
    channel.setMethodCallHandler(this);
    mPlayers = new SparseArray();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if(call.method.equals("createVodPlayer")) {
      FTXVodPlayer player = new FTXVodPlayer(mFlutterPluginBinding);
      int playerId = player.getPlayerId();
      mPlayers.append(playerId, player);
      result.success(playerId);
    } else if(call.method.equals("createLivePlayer")) {
      FTXLivePlayer player = new FTXLivePlayer(mFlutterPluginBinding,mActivityPluginBinding.getActivity());
      int playerId = player.getPlayerId();
      mPlayers.append(playerId, player);
      result.success(playerId);
    } else if(call.method.equals("releasePlayer")) {
      Integer playerId = call.argument("playerId");
      FTXBasePlayer player = mPlayers.get(playerId);
      if (player!=null){
        player.destory();
        mPlayers.remove(playerId);
      }
      result.success(null);
    } else if(call.method.equals("setConsoleEnabled")) {
      boolean bnabled = call.argument("enabled");
      TXLiveBase.setConsoleEnabled(bnabled);
      result.success(null);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    mFlutterPluginBinding = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    mActivityPluginBinding = binding;
    mFlutterPluginBinding.getPlatformViewRegistry().registerViewFactory("super_player_view", new SuperPlatformViewFactory(mFlutterPluginBinding, binding.getActivity()));
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }
}
