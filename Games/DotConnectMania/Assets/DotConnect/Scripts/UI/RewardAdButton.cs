using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BizzyBeeGames.DotConnect
{
	[RequireComponent(typeof(Button))]
	public class RewardAdButton : MonoBehaviour
	{

		#region Inspector Variables

		[SerializeField] private int hintsToReward;
		[SerializeField] public GameObject noadpopup;

		#endregion

		#region Properties

		public Button Button { get { return gameObject.GetComponent<Button>(); } }

		#endregion

		#region Unity Methods

		private void Awake()
		{
			
			Button.onClick.AddListener(OnClick);

			gameObject.SetActive(true);
           	//GoogleAdMobController.AdmobManager.OnRewardedEarned += OnRewardAdGranted;

          
        }
        private void Start()
        {
			// GoogleAdMobController.AdmobManager.OnRewardedEarned += () =>
			// {
			// 	Debug.Log("Working");
			// 	OnRewardAdGranted();
			// };
        }


        #endregion

        #region Private Methods

       private void OnClick()
		{
			if (GoogleAdsManager.Instance.CanShowRewardAd())
			{
				Debug.Log("[Hint] Showing reward ad, hintsToReward=" + hintsToReward);

				int levelNumber = GameManager.Instance.ActiveLevelData.LevelIndex + 1;

				GoogleAdsManager.Instance.ShowRewardAd("hint", "hint", levelNumber, OnRewardAdGranted);
			}
			else
			{
				Debug.Log("[Hint] CanShowRewardAd() returned false");
				noadpopup.SetActive(true);
			}
		}

		
		public void close()
		{
			noadpopup.SetActive(false);
		}

		public void closepopup()
		{
			gameObject.SetActive(false);
			OnRewardAdGranted();
		}

		private void OnRewardAdLoaded()
		{
			gameObject.SetActive(true);
		}

		private void OnRewardAdClosed()
		{
			gameObject.SetActive(true);
		}

		private void OnRewardAdGranted()
		{
			Debug.Log("[Hint] OnRewardAdGranted fired. HintAmount before=" + GameManager.Instance.HintAmount);
			GameManager.Instance.GiveHints(hintsToReward);
			Debug.Log("[Hint] HintAmount after=" + GameManager.Instance.HintAmount);
		}

		private void OnAdsRemoved()
		{
			//MobileAdsManager.Instance.OnRewardAdLoaded -= OnRewardAdLoaded;
			gameObject.SetActive(true);
		}

		#endregion
	}
}
