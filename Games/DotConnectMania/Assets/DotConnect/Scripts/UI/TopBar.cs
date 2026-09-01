using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BizzyBeeGames.DotConnect
{
	public class TopBar : MonoBehaviour
	{
		#region Inspector Variables

		[SerializeField] private CanvasGroup	backButton		= null;
		[SerializeField] private Text			headerText		= null;
		[SerializeField] private Text			starAmountText	= null;

		#endregion

		#region Member Variables

		private BundleInfo selectedBundleInfo;

		#endregion

		#region Unity Methods

		private void Start()
		{
			backButton.alpha = 0f;

			UpdateStarsText();

			ScreenManager.Instance.OnSwitchingScreens += OnSwitchingScreens;

			GameEventManager.Instance.RegisterEventHandler(GameEventManager.EventId_BundleSelected, OnBundleSelected);
			GameEventManager.Instance.RegisterEventHandler(GameEventManager.EventId_LevelStarted, OnLevelStarted);
			GameEventManager.Instance.RegisterEventHandler(GameEventManager.EventId_StarsIncreased, OnStarsIncreased);
		}

		#endregion

		#region Private Methods

		private void OnBundleSelected(string eventId, object[] data)
		{
			selectedBundleInfo = data[0] as BundleInfo;
		}

		private void OnSwitchingScreens(string fromScreenId, string toScreenId)
		{
			if (fromScreenId == ScreenManager.Instance.HomeScreenId)
			{
				UIAnimation anim = UIAnimation.Alpha(backButton, 1f, 0.35f);

				anim.style = UIAnimation.Style.EaseOut;

				anim.Play();
			}
			else if (toScreenId == ScreenManager.Instance.HomeScreenId)
			{
				UIAnimation anim = UIAnimation.Alpha(backButton, 0f, 0.35f);

				anim.style = UIAnimation.Style.EaseOut;

				anim.Play();
			}

			UpdateHeaderText(toScreenId);
		}

		private void OnLevelStarted(string eventId, object[] data)
		{
			string text = string.Format("LEVEL {0}", GameManager.Instance.ActiveLevelData.LevelIndex + 1);

			if (ScreenManager.Instance.CurrentScreenId != "game")
			{
				UIAnimation.SwapText(headerText, text, 0.5f);
			}
			else
			{
				headerText.text = text;
			}
		}

		private void OnStarsIncreased(string eventId, object[] data)
		{
			UpdateStarsText();
		}

		private void UpdateHeaderText(string toScreenId)
		{
			switch (toScreenId)
			{
				case "main":
					UIAnimation.SwapText(headerText, "", 0.5f);
					break;
				case "bundles":
					UIAnimation.SwapText(headerText, "BUNDLES", 0.5f);
					break;
				case "pack_levels":
					UIAnimation.SwapText(headerText, selectedBundleInfo.BundleName, 0.5f);
					break;
			}
		}

		private void UpdateStarsText()
		{
			starAmountText.text = GameManager.Instance.StarAmount.ToString();
		}

		#endregion
	}
}
