using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System;

namespace BizzyBeeGames.DotConnect
{
	public class GameManager : SingletonComponent<GameManager>, ISaveable
	{
		#region Inspector Variables
		[SerializeField] GameObject hintbutton;		
		[Header("Data")]
		[SerializeField] private List<BundleInfo>	bundleInfos			= null;
		[SerializeField] private int				startingHints		= 5;
		[SerializeField] private int				numLevelsForGift	= 25;

		[Header("Ads")]
		[SerializeField] private int				numLevelsBetweenAds	= 0;

		[Header("UI Components")]
		[SerializeField] private GameGrid			gameGrid		= null;
		[SerializeField] private Text				hintAmountText	= null;
		[SerializeField] private Button				lastLevelButton	= null;
		[SerializeField] private Button				nextLevelButton	= null;

		[Header("Debug")]
		[SerializeField] private bool				unlockAllPacks	= false;	// Sets all packs to be unlocked
		[SerializeField] private bool				unlockAllLevels	= false;	// Sets all levels to be unlocked (does not unlock packs)
		[SerializeField] private bool				freeHints		= false;	// You can used hints regardless of the amount of hints you have
		[SerializeField] private int				startingStars	= 0;		// Sets the amount of stars you have when the game runs, overrides saved value

		#endregion

		#region Member Variables

		private Dictionary<string, int>						packNumStarsEarned;
		private Dictionary<string, int>						packLastCompletedLevel;
		private Dictionary<string, Dictionary<int, int>>	packLevelStatuses;
		private Dictionary<string, LevelSaveData>			levelSaveDatas;
		public Button gameoverNextLevelButn;
        public Button gameoverReplayLevelButn;

        #endregion

        #region Properties

        public List<BundleInfo>	BundleInfos		{ get { return bundleInfos; } }
		public PackInfo			ActivePackInfo	{ get; private set; }
		public LevelData		ActiveLevelData	{ get; private set; }
		public int				StarAmount		{ get; private set; }
		public int				HintAmount		{ get; private set; }
		public int				NumLevelsTillAd	{ get; private set; }
		
		public string SaveId { get { return "game"; } }

		// member variables
		private HashSet<string> adUnlockedLevelIds = new HashSet<string>();
		private PackInfo pendingUnlockPackInfo;
		private LevelData pendingUnlockLevelData;

		/// <summary>Level currently pending an ad-unlock, for the unlock button's analytics call. Null if none pending.</summary>
		public LevelData PendingUnlockLevelData { get { return pendingUnlockLevelData; } }

		
		#endregion

		#region Unity Methods


		protected override void Awake()
		{
			base.Awake();

			GameEventManager.Instance.RegisterEventHandler(GameEventManager.EventId_ActiveLevelCompleted, OnActiveLevelComplete);

			SaveManager.Instance.Register(this);

			packNumStarsEarned		= new Dictionary<string, int>();
			packLastCompletedLevel	= new Dictionary<string, int>();
			packLevelStatuses		= new Dictionary<string, Dictionary<int, int>>();
			levelSaveDatas			= new Dictionary<string, LevelSaveData>();

			if (!LoadSave())
			{
				HintAmount		= startingHints;
				NumLevelsTillAd	= numLevelsBetweenAds;
			}

			gameGrid.Initialize();

			if (startingStars > 0)
			{
				StarAmount = startingStars;
			}

			StartCoroutine(ShowLaunchAppOpen());

			
		}

		private IEnumerator ShowLaunchAppOpen()
		{
			if (PlayerPrefs.GetInt("premium", 0) == 1)
			{
				ScreenManager.Instance.ShowHomeScreen();
				yield break;
			}

			// Wait for GoogleAdsManager to exist (Awake order isn't guaranteed across objects)
			float initWaitTimeout = 5f;
			float initWaitTimer = 0f;

			while (GoogleAdsManager.Instance == null && initWaitTimer < initWaitTimeout)
			{
				initWaitTimer += Time.deltaTime;
				yield return null;
			}

			if (GoogleAdsManager.Instance == null)
			{
				Debug.LogWarning("GoogleAdsManager never initialized — skipping launch app open ad.");
				ScreenManager.Instance.ShowHomeScreen();
				yield break;
			}

			float timeout = 8f;
			float timer = 0f;

			while (!GoogleAdsManager.Instance.CanShowAppOpen() && timer < timeout)
			{
				timer += Time.deltaTime;
				yield return null;
			}

			if (!GoogleAdsManager.Instance.CanShowAppOpen())
			{
				Debug.Log("Launch app open ad not ready after timeout — skipping.");
				ScreenManager.Instance.ShowHomeScreen();
				yield break;
			}

			yield return new WaitForSeconds(0.5f);

			GoogleAdsManager.Instance.ShowAppOpen(() =>
			{
				ScreenManager.Instance.ShowHomeScreen();
			});
		}

	
		private void OnDestroy()
		{
			GameAnalyticsManager.Instance.GameplaySessionEnd();
			Save();
		}
	

		private void OnApplicationPause(bool pause)
		{
			if (pause)
			{
				GameAnalyticsManager.Instance.GameplaySessionEnd();
				Save();
			}
		}

		#endregion

		#region Public Variables

		
		public void StartLevel(PackInfo packInfo, LevelData levelData)
		{
			// levels are 0-indexed internally (LevelIndex) — log the human-facing 1-based number
			GameAnalyticsManager.Instance.LevelStart(levelData.LevelIndex + 1);

			ActivePackInfo	= packInfo;
			ActiveLevelData	= levelData;

			// Check if the lvel has not been started and if there is loaded save data for it
			if (!levelSaveDatas.ContainsKey(levelData.Id))
			{
				levelSaveDatas[levelData.Id] = new LevelSaveData();
			}

			gameGrid.SetupLevel(levelData, levelSaveDatas[levelData.Id]);

			UpdateHintAmountText();
			UpdateLevelButtons();

			GameEventManager.Instance.SendEvent(GameEventManager.EventId_LevelStarted);

			ScreenManager.Instance.Show("game");

		}

	
		public void NextLevel()
		{
			int nextLevelIndex = ActiveLevelData.LevelIndex + 1;

			if (nextLevelIndex < ActivePackInfo.LevelDatas.Count)
			{
				StartLevel(ActivePackInfo, ActivePackInfo.LevelDatas[nextLevelIndex]);
			}
		}

		public void LastLevel()
		{
			int lastLevelIndex = ActiveLevelData.LevelIndex - 1;

			if (lastLevelIndex >= 0)
			{
				StartLevel(ActivePackInfo, ActivePackInfo.LevelDatas[lastLevelIndex]);
			}
		}

		
		public bool IsLevelCompleted(LevelData levelData)
		{
			if (!packLevelStatuses.ContainsKey(levelData.PackId))
			{
				return false;
			}

			Dictionary<int, int> levelStatuses = packLevelStatuses[levelData.PackId];

			if (!levelStatuses.ContainsKey(levelData.LevelIndex))
			{
				return false;
			}

			// If it has an entry in levelStatuses then it must have been completed 
			return true;
		}

		
		public bool HasEarnedStar(LevelData levelData)
		{
			return IsLevelCompleted(levelData) && packLevelStatuses[levelData.PackId][levelData.LevelIndex] == 1;
		}


		// called from LevelListScreen.OnLevelListItemClicked
		public void RequestPlayLockedLevel(PackInfo packInfo, LevelData levelData)
		{
			if (!IsLevelLocked(levelData))
			{
				StartLevel(packInfo, levelData);
				return;
			}
			

			pendingUnlockPackInfo  = packInfo;
			pendingUnlockLevelData = levelData;

			PopupManager.Instance.Show("unlock_level_locked");
		}

		//called by the new button script below, once the reward ad is granted
		public void UnlockPendingLevelViaAd()
		{
			if (pendingUnlockLevelData == null)
				return;

			LevelData levelData = pendingUnlockLevelData;
			PackInfo  packInfo   = pendingUnlockPackInfo;

			adUnlockedLevelIds.Add(levelData.Id);

			pendingUnlockLevelData = null;
			pendingUnlockPackInfo  = null;

			StartLevel(packInfo, levelData);
		}

		

		// update existing IsLevelLocked
		public bool IsLevelLocked(LevelData levelData)
		{
			if (unlockAllLevels) return false;
			if (adUnlockedLevelIds.Contains(levelData.Id)) return false;

			return levelData.LevelIndex > 0 && (!packLastCompletedLevel.ContainsKey(levelData.PackId) || levelData.LevelIndex > packLastCompletedLevel[levelData.PackId] + 1);
		}

		
		public bool IsPackLocked(PackInfo packInfo)
		{
			if (unlockAllPacks) return false;

			switch (packInfo.unlockType)
			{
				case PackUnlockType.Stars:
					return StarAmount < packInfo.unlockStarsAmount;
				case PackUnlockType.IAP:
					return IAPManager.Exists() && !IAPManager.Instance.IsProductPurchased(packInfo.unlockIAPProductId);
			}

			return false;
		}


		public int GetNumCompletedLevels(PackInfo packInfo)
		{
			if (!packLastCompletedLevel.ContainsKey(packInfo.packId))
			{
				return 0;
			}

			return packLastCompletedLevel[packInfo.packId] + 1;
		}

		public float GetPackProgress(PackInfo packInfo)
		{
			return (float)(GetNumCompletedLevels(packInfo)) / (float)packInfo.levelFiles.Count;
		}

		public void ShowHint()
		{
			if (HintAmount > 0 || freeHints)
			{
				HintAmount = Mathf.Clamp(HintAmount - 1, 0, int.MaxValue);

				UpdateHintAmountText();

				gameGrid.ShowHint();
			}
			else
			{
				PopupManager.Instance.Show("not_enough_hints");
				UpdateHintAmountText();
			}
		}

		
		public void GiveHints(int amount)
		{
			HintAmount += amount;

			UpdateHintAmountText();
		}

		#endregion

		#region Private Variables

	
		void Adv()
		{
			
			gameoverNextLevelButn.interactable = true;
			gameoverReplayLevelButn.interactable = true;
        }

		private void OnActiveLevelComplete(string eventId, object[] data)
		{
			
			GameAnalyticsManager.Instance.LevelEnd(success: true, endReason: "completed");

            gameoverNextLevelButn.interactable = false;
            gameoverReplayLevelButn.interactable = false;

            // Get the number of moves it took to complete the level
            int numMoves = (int)data[0];

			// Check if the user gets a star for completeing the level in the minimum number of moves
			bool earnedStar			= (numMoves <= ActiveLevelData.LinePositions.Count);
			bool alreadyEarnedStar	= HasEarnedStar(ActiveLevelData);

			// Check if they just earned a new star
			if (earnedStar && !alreadyEarnedStar)
			{
				IncreaseStarAmount(1);
			}

			// Get gift progress information
			int		lastLevelCompleted	= (packLastCompletedLevel.ContainsKey(ActiveLevelData.PackId) ? packLastCompletedLevel[ActiveLevelData.PackId] : -1);
			bool	giftProgressed 		= (ActiveLevelData.LevelIndex > lastLevelCompleted);
			int		fromGiftProgress	= (lastLevelCompleted + 1);
			int		toGiftProgress		= (ActiveLevelData.LevelIndex + 1);
			bool	giftAwarded			= (giftProgressed && toGiftProgress % numLevelsForGift == 0);

			// Give one hint if a gift should be awarded
			if (giftAwarded)
			{
				HintAmount += 1;
			}

			// Set the active level as completed
			SetLevelComplete(ActiveLevelData, earnedStar ? 1 : 0);

			// Remove the save data since it's only for levels which have been started but not completed
			levelSaveDatas.Remove(ActiveLevelData.Id);

			bool isLastLevel = (ActiveLevelData.LevelIndex == ActivePackInfo.LevelDatas.Count - 1);

			// Create the data object array to pass to the level complete popup
			object[] popupData = 
			{
				isLastLevel,
				numMoves,
				ActiveLevelData.LinePositions.Count, // Number of moves to earn a star
				earnedStar,
				alreadyEarnedStar,
				giftProgressed,
				giftAwarded,
				fromGiftProgress,
				toGiftProgress,
				numLevelsForGift
			};

			SoundManager.Instance.Play("level-completed");

			if (PlayerPrefs.GetInt("premium", 0) != 1)
			{
				
				if (GameAnalyticsManager.Instance.ShouldShowEveryThirdLevelInterstitial())
				{
					StartCoroutine(ShowLevelCompleteInterstitial());
				}
			}
	
            
			Debug.Log(ActiveLevelData.LevelIndex + 1);
            PopupManager.Instance.Show("level_complete", popupData, OnLevelCompletePopupClosed);
            nextLevelButton.interactable = false;
            lastLevelButton.interactable = false;
			Invoke("Adv", 0.1f);
			Debug.Log("P");
            

            NumLevelsTillAd--;
		}

		private IEnumerator ShowLevelCompleteInterstitial()
		{
			// Don't show ads for premium users
			if (PlayerPrefs.GetInt("premium", 0) == 1)
				yield break;

			float timeout = 6f; // seconds to wait for an ad to be ready
			float timer = 0f;

			while (!GoogleAdsManager.Instance.CanShowInterstitial() && timer < timeout)
			{
				timer += Time.deltaTime;
				yield return null;
			}

			if (GoogleAdsManager.Instance.CanShowInterstitial())
			{
				GoogleAdsManager.Instance.ShowInterstitial("every_3_levels",
					levelNumberDiagnostic: ActiveLevelData.LevelIndex + 1);
			}
			else
			{
				Debug.Log("Interstitial still not ready after timeout — skipping this trigger.");
			}
		}

		private void OnLevelCompletePopupClosed(bool cancelled, object[] data)
		{
			string action = data[0] as string;

			switch (action)
			{
				case "next_level":
					NextLevel();
					break;
				case "replay":
					StartLevel(ActivePackInfo, ActiveLevelData);
					break;
				case "back_to_level_list":
					ScreenManager.Instance.Back();
					break;
				case "back_to_bundle_list":
					ScreenManager.Instance.BackTo("bundles");
					break;
			}
		}

		private void SetLevelComplete(LevelData levelData, int status)
		{
			int curLastCompletedLevel = packLastCompletedLevel.ContainsKey(levelData.PackId) ? packLastCompletedLevel[levelData.PackId] : -1;

			if (levelData.LevelIndex == curLastCompletedLevel + 1)
			{
				packLastCompletedLevel[levelData.PackId] = levelData.LevelIndex;
			}

			if (!packLevelStatuses.ContainsKey(levelData.PackId))
			{
				packLevelStatuses.Add(levelData.PackId, new Dictionary<int, int>());
			}

			Dictionary<int, int> levelStatuses = packLevelStatuses[levelData.PackId];
			int curStatus = levelStatuses.ContainsKey(levelData.LevelIndex) ? levelStatuses[levelData.LevelIndex] : -1;

			if (status > curStatus)
			{
				levelStatuses[levelData.LevelIndex] = status;
			}
		}
		private void IncreaseStarAmount(int amt)
		{
			StarAmount += amt;

			GameEventManager.Instance.SendEvent(GameEventManager.EventId_StarsIncreased);
		}

		private void UpdateHintAmountText()
		{
			if (HintAmount > 0)
			{
				hintAmountText.text = HintAmount.ToString();
			}
			else
			{
				hintAmountText.text = "+";
			}
		}

		private void UpdateLevelButtons()
		{
			int nextLevelIndex = ActiveLevelData.LevelIndex + 1;

			nextLevelButton.interactable = nextLevelIndex < ActivePackInfo.LevelDatas.Count && !IsLevelLocked(ActivePackInfo.LevelDatas[nextLevelIndex]);
			lastLevelButton.interactable = ActiveLevelData.LevelIndex > 0;
		}

		public Dictionary<string, object> Save()
		{
			Dictionary<string, object> json = new Dictionary<string, object>();

			json["num_stars_earned"]	= SaveNumStarsEarned();
			json["last_completed"]		= SaveLastCompleteLevels();
			json["level_statuses"]		= SaveLevelStatuses();
			json["level_save_datas"]	= SaveLevelDatas();
			json["star_amount"]			= StarAmount;
			json["hint_amount"]			= HintAmount;
			json["num_levels_till_ad"]	= NumLevelsTillAd;
			json["ad_unlocked_levels"] = new List<object>(adUnlockedLevelIds);

			return json;
		}

		private List<object> SaveNumStarsEarned()
		{
			List<object> json = new List<object>();

			foreach (KeyValuePair<string, int> pair in packNumStarsEarned)
			{
				Dictionary<string, object> packJson = new Dictionary<string, object>();

				packJson["pack_id"]				= pair.Key;
				packJson["num_stars_earned"]	= pair.Value;

				json.Add(packJson);
			}

			return json;
		}

		private List<object> SaveLastCompleteLevels()
		{
			List<object> json = new List<object>();

			foreach (KeyValuePair<string, int> pair in packLastCompletedLevel)
			{
				Dictionary<string, object> packJson = new Dictionary<string, object>();

				packJson["pack_id"]					= pair.Key;
				packJson["last_completed_level"]	= pair.Value;

				json.Add(packJson);
			}

			return json;
		}

		private List<object> SaveLevelStatuses()
		{
			List<object> json = new List<object>();

			foreach (KeyValuePair<string, Dictionary<int, int>> pair in packLevelStatuses)
			{
				Dictionary<string, object> packJson = new Dictionary<string, object>();

				packJson["pack_id"] = pair.Key;

				string levelStr = "";

				foreach (KeyValuePair<int, int> levelPair in pair.Value)
				{
					if (!string.IsNullOrEmpty(levelStr)) levelStr += "_";
					levelStr += levelPair.Key + "_" + levelPair.Value;
				}

				packJson["level_statuses"] = levelStr;

				json.Add(packJson);
			}

			return json;
		}

		private List<object> SaveLevelDatas()
		{
			List<object> savedLevelDatas = new List<object>();

			foreach (KeyValuePair<string, LevelSaveData> pair in levelSaveDatas)
			{
				Dictionary<string, object> levelSaveDataJson = pair.Value.Save();

				levelSaveDataJson["id"] = pair.Key;

				savedLevelDatas.Add(levelSaveDataJson);
			}

			return savedLevelDatas;
		}

		private bool LoadSave()
		{
			JSONNode json = SaveManager.Instance.LoadSave(this);

			if (json == null)
			{
				return false;
			}

			LoadNumStarsEarned(json["num_stars_earned"].AsArray);
			LoadLastCompleteLevels(json["last_completed"].AsArray);
			LoadLevelStatuses(json["level_statuses"].AsArray);
			LoadLevelSaveDatas(json["level_save_datas"].AsArray);
			LoadAdUnlockedLevels(json["ad_unlocked_levels"].AsArray);

			StarAmount		= json["star_amount"].AsInt;
			HintAmount		= json["hint_amount"].AsInt;
			NumLevelsTillAd	= json["num_levels_till_ad"].AsInt;

			return true;
		}

		private void LoadAdUnlockedLevels(JSONArray json)
		{
			for (int i = 0; i < json.Count; i++)
			{
				adUnlockedLevelIds.Add(json[i].Value);
			}
		}

		private void LoadNumStarsEarned(JSONArray json)
		{
			for (int i = 0; i < json.Count; i++)
			{
				JSONNode childJson = json[i];

				string	packId			= childJson["pack_id"].Value;
				int		numStarsEarned	= childJson["num_stars_earned"].AsInt;

				packNumStarsEarned.Add(packId, numStarsEarned);
			}
		}

		private void LoadLastCompleteLevels(JSONArray json)
		{
			for (int i = 0; i < json.Count; i++)
			{
				JSONNode childJson = json[i];

				string	packId				= childJson["pack_id"].Value;
				int		lastCompletedLevel	= childJson["last_completed_level"].AsInt;

				packLastCompletedLevel.Add(packId, lastCompletedLevel);
			}
		}

		private void LoadLevelStatuses(JSONArray json)
		{
			for (int i = 0; i < json.Count; i++)
			{
				JSONNode childJson = json[i];

				string		packId			= childJson["pack_id"].Value;
				string[]	levelStatusStrs	= childJson["level_statuses"].Value.Split('_');

				Dictionary<int, int> levelStatuses = new Dictionary<int, int>();

				for (int j = 0; j < levelStatusStrs.Length; j += 2)
				{
					int levelIndex	= System.Convert.ToInt32(levelStatusStrs[j]);
					int status		= System.Convert.ToInt32(levelStatusStrs[j + 1]);

					levelStatuses.Add(levelIndex, status);
				}

				packLevelStatuses.Add(packId, levelStatuses);
			}
		}

		private void LoadLevelSaveDatas(JSONArray savedLevelDatasJson)
		{
			// Load all the placed line segments for levels that have progress
			for (int i = 0; i < savedLevelDatasJson.Count; i++)
			{
				JSONNode	savedLevelDataJson		= savedLevelDatasJson[i];
				JSONArray	savedPlacedLineSegments	= savedLevelDataJson["placed_line_segments"].AsArray;
				JSONArray	savedHints				= savedLevelDataJson["hints"].AsArray;

				List<List<CellPos>> placedLineSegments = new List<List<CellPos>>();

				for (int j = 0; j < savedPlacedLineSegments.Count; j++)
				{
					placedLineSegments.Add(new List<CellPos>());

					for (int k = 0; k < savedPlacedLineSegments[j].Count; k += 2)
					{
						placedLineSegments[j].Add(new CellPos(savedPlacedLineSegments[j][k].AsInt, savedPlacedLineSegments[j][k + 1].AsInt));
					}
				}

				List<int> hintLineIndices = new List<int>();

				for (int j = 0; j < savedHints.Count; j++)
				{
					hintLineIndices.Add(savedHints[j].AsInt);
				}

				string	levelId		= savedLevelDataJson["id"].Value;
				int		numMoves	= savedLevelDataJson["num_moves"].AsInt;

				LevelSaveData levelSaveData = new LevelSaveData();

				levelSaveData.placedLineSegments	= placedLineSegments;
				levelSaveData.numMoves				= numMoves;
				levelSaveData.hintLineIndices		= hintLineIndices;

				try
				{
					if(!levelSaveDatas.ContainsKey(levelId))
						levelSaveDatas.Add(levelId, levelSaveData);
                }
				catch(Exception ex)
				{
					Debug.LogException(ex);
				}
			}
		}
		
		#endregion
	}
}