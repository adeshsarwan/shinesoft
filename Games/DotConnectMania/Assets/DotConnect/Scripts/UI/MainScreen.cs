using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BizzyBeeGames.DotConnect
{
	public class MainScreen : Screen
	{
		#region Inspector Variables

		[SerializeField] private GameObject	removeAdsButton;

		#endregion

		#region Unity Methods

		protected override void Start()
		{
			base.Start();

			//bool adsRemoved = MobileAdsManager.Instance.AdsRemoved;

			//removeAdsButton.SetActive(!adsRemoved);

			//if (!adsRemoved)
			//{
			//	MobileAdsManager.Instance.OnAdsRemoved += () => { removeAdsButton.SetActive(false); };
			//}
		}

		#endregion
	}
}
