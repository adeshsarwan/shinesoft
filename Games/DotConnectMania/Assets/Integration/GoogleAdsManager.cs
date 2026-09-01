using System;
using GoogleMobileAds.Api;
using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

public class GoogleAdsManager : MonoBehaviour
{
    public static GoogleAdsManager Instance;

    [Header("AdMob IDs")]

#if UNITY_ANDROID
    private string bannerID;
    [SerializeField] private string interstitialID;
    [SerializeField] private string rewardedID;
    [SerializeField] private string appOpenID;
    [SerializeField] private string nativeOverlayID;


#elif UNITY_IOS
    private string bannerID        = "ca-app-pub-3940256099942544/2934735716";
    private string interstitialID  = "ca-app-pub-3940256099942544/4411468910";
    private string rewardedID      = "ca-app-pub-3940256099942544/1712485313";
    private string appOpenID       = "ca-app-pub-3940256099942544/5662855259";
    private string nativeOverlayID = "ca-app-pub-3940256099942544/3986624511";
#else
    private string bannerID        = "unused";
    private string interstitialID  = "unused";
    private string rewardedID      = "unused";
    private string appOpenID       = "unused";
    private string nativeOverlayID = "unused";
#endif

    private BannerView bannerView;
    private InterstitialAd interstitialAd;
    private RewardedAd rewardedAd;
    private AppOpenAd appOpenAd;
    private NativeOverlayAd nativeOverlayAd;

    private bool isInitialized = false;

    private Action pendingInterstitialClosedCallback;

    private Action pendingAppOpenClosedCallback;

    
    private string pendingInterstitialPlacement;
    private int? pendingInterstitialLevelNumber;

    private string pendingRewardedPlacement;
    private string pendingRewardedRewardType;
    private int pendingRewardedLevelNumber;

    private string currentScreenName = "unknown";

    private readonly Queue<Action> mainThreadActions = new Queue<Action>();
    private readonly object mainThreadLock = new object();

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }

    private void Start()
    {
        InitializeAds();
    }

    private void RunOnMainThread(Action action)
    {
        if (action == null) return;

        lock (mainThreadLock)
        {
            mainThreadActions.Enqueue(action);
        }
    }

    private void Update()
    {
        lock (mainThreadLock)
        {
            while (mainThreadActions.Count > 0)
            {
                mainThreadActions.Dequeue()?.Invoke();
            }
        }
    }

    /// <summary>Call from ScreenManager whenever the visible screen changes (menu, level_select, in_level, etc).</summary>
    public void SetCurrentScreen(string screenName)
    {
        currentScreenName = screenName;
    }

    
    private void LogAdImpression(string adFormat, string placement, AdValue adValue,
        ResponseInfo responseInfo, int? levelNumberDiagnostic = null, string screenName = null)
    {
        string adSource = "admob";

        try
        {
            var adapterInfo = responseInfo?.GetLoadedAdapterResponseInfo();
            if (adapterInfo != null && !string.IsNullOrEmpty(adapterInfo.AdSourceName))
            {
                adSource = adapterInfo.AdSourceName;
            }
        }
        catch (Exception e)
        {
            Debug.LogWarning("[GoogleAdsManager] Could not read adapter response info: " + e.Message);
        }

        GameAnalyticsManager.Instance.AdImpression(
            adFormat: adFormat,
            placement: placement,
            adPlatform: "admob",
            adSource: adSource,
            adUnitName: placement,
            value: adValue.Value,
            currency: adValue.CurrencyCode,
            levelNumberDiagnostic: levelNumberDiagnostic,
            screenName: screenName);
    }


    public void InitializeAds()
    {
        MobileAds.Initialize((InitializationStatus status) =>
        {
            RunOnMainThread(() =>
            {
                Debug.Log("AdMob Initialized");

                isInitialized = true;

                //LoadBanner();
                LoadInterstitial();
                LoadRewardAd();
                LoadAppOpen();
                LoadNativeAd();
            });
        });
    }


    public void LoadBanner()
    {
        if (!isInitialized)
            return;

        if (bannerView != null)
        {
            bannerView.Destroy();
        }


        bannerView = new BannerView(bannerID, AdSize.MediumRectangle, AdPosition.Bottom);

        AdRequest request = new AdRequest();
        bannerView.LoadAd(request);

        Debug.Log("Banner Loaded");
    }

    public void ShowBanner()
    {
        if (bannerView != null)
        {
            bannerView.Show();
        }
    }

    public void HideBanner()
    {
        if (bannerView != null)
        {
            bannerView.Hide();
        }
    }

    public void DestroyBanner()
    {
        if (bannerView != null)
        {
            bannerView.Destroy();
            bannerView = null;
        }
    }


    public void LoadInterstitial()
    {
        AdRequest request = new AdRequest();

        InterstitialAd.Load(interstitialID, request, (InterstitialAd ad, LoadAdError error) =>
        {
            RunOnMainThread(() =>
            {
                if (error != null)
                {
                    Debug.Log("Interstitial Load Failed : " + error);
                    return;
                }

                interstitialAd = ad;
                Debug.Log("Interstitial Loaded");

                interstitialAd.OnAdFullScreenContentClosed += () =>
                {
                    RunOnMainThread(() =>
                    {
                        Debug.Log("Interstitial Closed");

                        interstitialAd.Destroy();
                        interstitialAd = null;

                        var callback = pendingInterstitialClosedCallback;
                        pendingInterstitialClosedCallback = null;

                        Debug.Log("[GoogleAdsManager] invoking closed callback, is null? " + (callback == null));
                        callback?.Invoke();

                        LoadInterstitial();
                    });
                };

                interstitialAd.OnAdFullScreenContentFailed += (AdError error2) =>
                {
                    RunOnMainThread(() =>
                    {
                        Debug.Log("Interstitial Failed: " + error2);

                        interstitialAd.Destroy();
                        interstitialAd = null;

                        var callback = pendingInterstitialClosedCallback;
                        pendingInterstitialClosedCallback = null;
                        callback?.Invoke();

                        LoadInterstitial();
                    });
                };

                interstitialAd.OnAdPaid += (AdValue adValue) =>
                {
                    RunOnMainThread(() =>
                    {
                        LogAdImpression("interstitial", pendingInterstitialPlacement, adValue,
                            interstitialAd?.GetResponseInfo(), pendingInterstitialLevelNumber);
                    });
                };
            });
        });
    }

    public bool CanShowInterstitial()
    {
        return interstitialAd != null && interstitialAd.CanShowAd();
    }

    public void ShowInterstitial(string placement, Action onClosed = null, int? levelNumberDiagnostic = null)
    {
        if (interstitialAd != null && interstitialAd.CanShowAd())
        {
            pendingInterstitialClosedCallback = onClosed;
            pendingInterstitialPlacement = placement;
            pendingInterstitialLevelNumber = levelNumberDiagnostic;
            interstitialAd.Show();
        }
        else
        {
            Debug.Log("Interstitial Not Ready");
            onClosed?.Invoke(); // nothing to show, so "done" fires immediately
        }
    }

    public void LoadRewardAd()
    {
        AdRequest request = new AdRequest();

        RewardedAd.Load(rewardedID, request, (RewardedAd ad, LoadAdError error) =>
        {
            RunOnMainThread(() =>
            {
                if (error != null)
                {
                    Debug.Log("Reward Load Failed : " + error);
                    return;
                }

                rewardedAd = ad;
                Debug.Log("Reward Ad Loaded");

                rewardedAd.OnAdPaid += (AdValue adValue) =>
                {
                    RunOnMainThread(() =>
                    {
                        LogAdImpression("rewarded", pendingRewardedPlacement, adValue,
                            rewardedAd?.GetResponseInfo(), pendingRewardedLevelNumber);
                    });
                };
            });
        });
    }

    public bool CanShowRewardAd()
    {
        return rewardedAd != null;
    }

    public void ShowRewardAd(string placement, string rewardType, int levelOrRoundNumber, Action rewardGrantedCallback)
    {
        if (rewardedAd != null)
        {
            pendingRewardedPlacement = placement;
            pendingRewardedRewardType = rewardType;
            pendingRewardedLevelNumber = levelOrRoundNumber;

            rewardedAd.Show((Reward reward) =>
            {
                RunOnMainThread(() =>
                {
                    Debug.Log("Reward Completed");

                    // Reward actually granted — this is the one true trigger for rewarded_ad_used.
                    GameAnalyticsManager.Instance.RewardedAdUsed(placement, rewardType, levelOrRoundNumber);

                    rewardGrantedCallback?.Invoke();
                });
            });

            rewardedAd = null;
            LoadRewardAd();
        }
        else
        {
            Debug.Log("Reward Ad Not Available");
            LoadRewardAd();
        }
    }

    public void LoadAppOpen()
    {
        AdRequest request = new AdRequest();

        AppOpenAd.Load(appOpenID, request, (AppOpenAd ad, LoadAdError error) =>
        {
            RunOnMainThread(() =>
            {
                if (error != null)
                {
                    Debug.Log("App Open Load Failed : " + error);
                    return;
                }

                appOpenAd = ad;
                Debug.Log("App Open Loaded");

                appOpenAd.OnAdFullScreenContentClosed += () =>
                {
                    RunOnMainThread(() =>
                    {
                        Debug.Log("App Open Closed");

                        appOpenAd.Destroy();
                        appOpenAd = null;

                        var callback = pendingAppOpenClosedCallback;
                        pendingAppOpenClosedCallback = null;

                        callback?.Invoke();

                        LoadAppOpen();
                    });
                };

                appOpenAd.OnAdFullScreenContentFailed += (AdError error2) =>
                {
                    RunOnMainThread(() =>
                    {
                        Debug.Log("App Open Failed: " + error2);

                        appOpenAd.Destroy();
                        appOpenAd = null;

                        var callback = pendingAppOpenClosedCallback;
                        pendingAppOpenClosedCallback = null;
                        callback?.Invoke();

                        LoadAppOpen();
                    });
                };

                appOpenAd.OnAdPaid += (AdValue adValue) =>
                {
                    RunOnMainThread(() =>
                    {
                        LogAdImpression("interstitial", "app_launch", adValue, appOpenAd?.GetResponseInfo());
                    });
                };
            });
        });
    }

    public bool CanShowAppOpen()
    {
        return appOpenAd != null && appOpenAd.CanShowAd();
    }


    public void ShowAppOpen(Action onClosed = null)
    {
        if (appOpenAd != null && appOpenAd.CanShowAd())
        {
            pendingAppOpenClosedCallback = onClosed;
            appOpenAd.Show();
        }
        else
        {
            Debug.Log("App Open Ad Not Ready");
            onClosed?.Invoke(); // nothing to show, so "done" fires immediately
        }
    }

    public void LoadNativeAd()
    {
        // Clean up the old ad before loading a new one.
        if (nativeOverlayAd != null)
        {
            DestroyNativeAd();
        }

        Debug.Log("Loading native overlay ad.");

        AdRequest adRequest = new AdRequest();

        NativeAdOptions options = new NativeAdOptions
        {
            AdChoicesPlacement = AdChoicesPlacement.TopRightCorner,
            MediaAspectRatio = MediaAspectRatio.Any
        };

        NativeOverlayAd.Load(nativeOverlayID, adRequest, options, (NativeOverlayAd ad, LoadAdError error) =>
        {
            RunOnMainThread(() =>
            {
                if (error != null)
                {
                    Debug.LogError("Native Overlay ad failed to load with error: " + error);
                    return;
                }

                // The ad should always be non-null if the error is null, but
                // double-check to avoid a crash.
                if (ad == null)
                {
                    Debug.LogError("Unexpected error: Native Overlay ad load event fired with null ad and null error.");
                    return;
                }

                Debug.Log("Native Overlay ad loaded with response : " + ad.GetResponseInfo());

                nativeOverlayAd = ad;

                RegisterEventHandlers(ad);
                RenderNativeAd();
            });
        });
    }

    private void RegisterEventHandlers(NativeOverlayAd ad)
    {
        ad.OnAdClicked += () =>
        {
            RunOnMainThread(() => Debug.Log("Native Clicked"));
        };

        ad.OnAdPaid += (AdValue adValue) =>
        {
            RunOnMainThread(() =>
            {
                LogAdImpression("native", "bottom_persistent", adValue, ad.GetResponseInfo(),
                    screenName: currentScreenName);
            });
        };

        ad.OnAdImpressionRecorded += () =>
        {
            RunOnMainThread(() => Debug.Log("Impression"));
        };
    }

    public bool CanShowNativeAd()
    {
        return nativeOverlayAd != null;
    }

    public void RenderNativeAd()
    {
        if (nativeOverlayAd == null)
        {
            Debug.Log("Native Overlay ad not ready");
            return;
        }

        Debug.Log("Rendering Native Overlay ad.");

        NativeTemplateStyle style = new NativeTemplateStyle
        {
            TemplateId = "small",
            MainBackgroundColor = Color.white,
            CallToActionText = new NativeTemplateTextStyle
            {
                BackgroundColor = Color.green,
                FontSize = 9,
                Style = NativeTemplateFontStyle.Bold
            }
        };

        nativeOverlayAd.RenderTemplate(style, AdPosition.Bottom);
        ShowNativeAd();
    }

    public void ShowNativeAd()
    {
        if (nativeOverlayAd != null)
        {
            Debug.Log("Showing Native Overlay ad.");
            nativeOverlayAd.Show();
        }
    }

    public void HideNativeAd()
    {
        if (nativeOverlayAd != null)
        {
            Debug.Log("Hiding Native Overlay ad.");
            nativeOverlayAd.Hide();
        }
    }

    public void DestroyNativeAd()
    {
        if (nativeOverlayAd != null)
        {
            Debug.Log("Destroying native overlay ad.");
            nativeOverlayAd.Destroy();
            nativeOverlayAd = null;
        }
    }

}