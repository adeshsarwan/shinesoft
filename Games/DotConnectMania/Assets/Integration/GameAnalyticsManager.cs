using System.Collections.Generic;
using Firebase.Analytics;
using UnityEngine;

public class GameAnalyticsManager : MonoBehaviour
{
    public static GameAnalyticsManager Instance;

    // ---- per-level attempt state ----
    private int currentLevelNumber;
    private int currentAttemptNumber = 1;
    private float levelStartTime;
    private string previousEndReason = "";

    // ---- session counters (for gameplay_session_end) ----
    private int levelsStartedThisSession;
    private int levelsCompletedThisSession;
    private int failsThisSession;
    private float sessionStartTime;

    // ---- ad cadence tracking ----
    private int levelEndCountForAdCadence; // counts level_end events; drives every_3_levels

    // ---- user property caches (avoid redundant SetUserProperty calls) ----
    private int maxLevelReached;
    private int totalRewardedAds;
    private int totalInterstitialsSeen;

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
            return;
        }

        sessionStartTime = Time.realtimeSinceStartup;
    }

    private bool CanLog()
    {
        return FirebaseManager.Instance != null && FirebaseManager.Instance.IsReady;
    }


    /// <summary>Call the instant controls become playable for the level. isNewLevel=false for retries.</summary>
    public void LevelStart(int levelNumber, string mode = "normal", bool isNewLevel = true)
    {
        currentLevelNumber = levelNumber;
        if (isNewLevel) currentAttemptNumber = 1;
        levelStartTime = Time.realtimeSinceStartup;
        levelsStartedThisSession++;

        if (!CanLog()) return;

        FirebaseAnalytics.LogEvent("level_start",
            new Parameter("level_name", "level_" + levelNumber),
            new Parameter("level_number", levelNumber),
            new Parameter("attempt_number", currentAttemptNumber),
            new Parameter("mode", mode));
    }

    public void LevelEnd(bool success, string endReason)
    {
        int durationSec = Mathf.RoundToInt(Time.realtimeSinceStartup - levelStartTime);
        previousEndReason = endReason;
        levelEndCountForAdCadence++;

        if (success)
        {
            levelsCompletedThisSession++;
            if (currentLevelNumber > maxLevelReached)
            {
                maxLevelReached = currentLevelNumber;
                SetUserProperty("max_level_reached", maxLevelReached.ToString());
            }
        }
        else if (endReason == "failed")
        {
            failsThisSession++;
        }

        SetUserProperty("current_level", currentLevelNumber.ToString());

        if (CanLog())
        {
            FirebaseAnalytics.LogEvent("level_end",
                new Parameter("level_name", "level_" + currentLevelNumber),
                new Parameter("level_number", currentLevelNumber),
                new Parameter("success", success ? "1" : "0"),
                new Parameter("attempt_number", currentAttemptNumber),
                new Parameter("duration_sec", durationSec),
                new Parameter("end_reason", endReason));
        }
    }


    public void LevelRetry()
    {
        int level = currentLevelNumber;
        currentAttemptNumber++;

        if (CanLog())
        {
            FirebaseAnalytics.LogEvent("level_retry",
                new Parameter("level_number", level),
                new Parameter("attempt_number", currentAttemptNumber),
                new Parameter("previous_end_reason", previousEndReason));
        }

        LevelStart(level, isNewLevel: false);
    }

    /// <summary>Only call if Dot Connect has a tutorial.</summary>
    public void TutorialStep(string stepName, int stepNumber, string status)
    {
        if (!CanLog()) return;

        FirebaseAnalytics.LogEvent("tutorial_step",
            new Parameter("step_name", stepName),
            new Parameter("step_number", stepNumber),
            new Parameter("status", status));
    }

    /// <summary>Call when the game returns to the menu, backgrounds, or quits after gameplay.</summary>
    public void GameplaySessionEnd()
    {
        if (CanLog())
        {
            FirebaseAnalytics.LogEvent("gameplay_session_end",
                new Parameter("levels_started", levelsStartedThisSession),
                new Parameter("levels_completed", levelsCompletedThisSession),
                new Parameter("fails", failsThisSession),
                new Parameter("duration_sec", Mathf.RoundToInt(Time.realtimeSinceStartup - sessionStartTime)));
        }

        levelsStartedThisSession = 0;
        levelsCompletedThisSession = 0;
        failsThisSession = 0;
        sessionStartTime = Time.realtimeSinceStartup;
    }

   
    public bool ShouldShowEveryThirdLevelInterstitial()
    {
        return levelEndCountForAdCadence % 3 == 0;
    }

  
    public void AdImpression(string adFormat, string placement, string adPlatform = "",
        string adSource = "", string adUnitName = "", double value = 0, string currency = "USD",
        int? levelNumberDiagnostic = null, string screenName = null)
    {
        if (adFormat == "interstitial")
        {
            totalInterstitialsSeen++;
            SetUserProperty("total_interstitials_seen", totalInterstitialsSeen.ToString());
        }

        if (!CanLog()) return;

        var parameters = new List<Parameter>
        {
            new Parameter("ad_format", adFormat),
            new Parameter("placement", placement),
            new Parameter("ad_platform", adPlatform),
            new Parameter("ad_source", adSource),
            new Parameter("ad_unit_name", adUnitName),
            new Parameter("value", value),
            new Parameter("currency", currency)
        };

        if (levelNumberDiagnostic.HasValue)
            parameters.Add(new Parameter("level_number", levelNumberDiagnostic.Value));

        if (!string.IsNullOrEmpty(screenName))
            parameters.Add(new Parameter("screen_name", screenName));

        FirebaseAnalytics.LogEvent("ad_impression", parameters.ToArray());
    }

  
    public void RewardedAdUsed(string placement, string rewardType, int levelNumber)
    {
        totalRewardedAds++;
        SetUserProperty("total_rewarded_ads", totalRewardedAds.ToString());

        if (!CanLog()) return;

        FirebaseAnalytics.LogEvent("rewarded_ad_used",
            new Parameter("placement", placement),
            new Parameter("level_number", levelNumber),
            new Parameter("reward_type", rewardType));
    }

    public void AdRequested(string adFormat, string placement)
    {
        if (!CanLog()) return;
        FirebaseAnalytics.LogEvent("ad_requested",
            new Parameter("ad_format", adFormat),
            new Parameter("placement", placement));
    }

    public void AdFailedToLoad(string adFormat, string placement, string errorCode)
    {
        if (!CanLog()) return;
        FirebaseAnalytics.LogEvent("ad_failed_to_load",
            new Parameter("ad_format", adFormat),
            new Parameter("placement", placement),
            new Parameter("error_code", errorCode));
    }

    private void SetUserProperty(string name, string value)
    {
        if (!CanLog()) return;
        FirebaseAnalytics.SetUserProperty(name, value);
    }
}