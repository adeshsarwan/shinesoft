// package com.snapdrama.shortstream;

// import android.app.Application;
// import com.snapdrama.shortstream.applicationPreference.ControlPreference;

// /**
//  * Global Application class to initialise IMA ad configuration.
//  * Add this class to AndroidManifest with android:name=".MyApplication".
//  */
// public class MyApplication extends Application {
//     @Override
//     public void onCreate() {
//         super.onCreate();
//         // Enable IMA ads globally (can be toggled at runtime if needed)
//         ControlPreference.setExoplayerImaShow(true);
//         // Force ad frequency to 4 (ad after every 4 reels)
//         ControlPreference.setExoplayerImaAfterReelsShowCount(4);
//         // Simple VAST URL that returns a single ad on each request
//         String defaultVastUrl = "https://pubads.g.doubleclick.net/gampad/ads" +
//                 "?iu=/21775744923/external/vast_ad_samples" +
//                 "&sz=640x480&ad_rule=1&output=vast&env=vp&cmsid=496&vid=short_onecue&correlator=";
//         ControlPreference.setVastExoPlayerUrl(defaultVastUrl);
//     }
// }
