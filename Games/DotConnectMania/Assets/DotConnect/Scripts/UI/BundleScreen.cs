using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BizzyBeeGames.DotConnect
{
	public class BundleScreen : Screen
	{
		#region Inspector Variables

		[Space]

		[SerializeField] private Text			bundleText			= null;
		[SerializeField] private Button			leftBundleButton	= null;
		[SerializeField] private Button			rightBundleButton	= null;
		[SerializeField] private RectTransform	packListContainer	= null;
		[SerializeField] private ScrollRect		packListScrollRect	= null;

		#endregion

		#region Member Variables

		private List<ObjectPool>	packListPools;
		private int					previousBundleIndex;
		private int					currentBundleIndex;

		private bool			isAnimatingContainers;
		private RectTransform	packListContainerClone;

		#endregion

		#region Properties

		private RectTransform ActivePackListContainer		{ get; set; }
		private RectTransform NonActivePackListContainer	{ get { return packListContainerClone == ActivePackListContainer ? packListContainer : packListContainerClone; } }

		#endregion

		#region Public Methods

		public override void Initialize()
		{
			base.Initialize();

			packListContainerClone = Instantiate(packListContainer, packListContainer.parent, false);

			packListPools = new List<ObjectPool>();

			for (int i = 0; i < GameManager.Instance.BundleInfos.Count; i++)
			{
				BundleInfo bundleInfo = GameManager.Instance.BundleInfos[i];

				packListPools.Add(new ObjectPool(bundleInfo.PackListItemPrefab.gameObject, 1, packListContainer));
			}

			previousBundleIndex	= -1;

			SetBundleIndex(0);

			ActivePackListContainer = packListContainer;

			if (IAPManager.Exists())
			{
				IAPManager.Instance.OnProductPurchased += OnProductPurchased;
			}
		}

		public override void Show(bool back, bool immediate)
		{
			base.Show(back, immediate);

			UpdateUI(false);
		}

		public void OnLeftButtonClicked()
		{
			if (isAnimatingContainers) return;

			previousBundleIndex = currentBundleIndex;

			SetBundleIndex(currentBundleIndex - 1);

			UpdateUI(true);
		}

		public void OnRightButtonClicked()
		{
			if (isAnimatingContainers) return;

			previousBundleIndex = currentBundleIndex;

			SetBundleIndex(currentBundleIndex + 1);

			UpdateUI(true);
		}

		#endregion

		#region Private Methods

		private void SetBundleIndex(int index)
		{
			currentBundleIndex = index;

			GameEventManager.Instance.SendEvent(GameEventManager.EventId_BundleSelected, GameManager.Instance.BundleInfos[currentBundleIndex]);
		}

		private void UpdateUI(bool animate)
		{
			packListPools[currentBundleIndex].ReturnAllObjectsToPool();

			// If we are animating, get the container that is not being used and therefore not visible on the screen, else use the one thats active
			RectTransform container = animate ? NonActivePackListContainer : ActivePackListContainer;

			// Get the bundle to display
			BundleInfo bundleInfo = GameManager.Instance.BundleInfos[currentBundleIndex];

			// Update the bundle header
			UpdateBundleHeader(bundleInfo, animate);

			// Setup the container with all the pack list items
			for (int i = 0; i < bundleInfo.PackInfos.Count; i++)
			{
				PackInfo		packInfo		= bundleInfo.PackInfos[i];
				PackListItem	packListItem	= packListPools[currentBundleIndex].GetObject<PackListItem>(container);

				packListItem.Setup(packInfo);

				packListItem.Data				= packInfo;
				packListItem.OnListItemClicked	= OnPackItemSelected;
			}

			packListScrollRect.content = container;
			container.anchoredPosition = new Vector2(container.anchoredPosition.x, 0f);

			if (animate)
			{
				// Disable the scroll rect so it doesn't mess with the containers position as we animate it
				packListScrollRect.enabled	= false;
				isAnimatingContainers		= true;

				UIAnimation	anim;
				float		fromX;
				float		toX;

				// Animate the active container off screen
				fromX	= 0;
				toX	= (previousBundleIndex > currentBundleIndex) ? RectT.rect.width : -RectT.rect.width;

				anim		= UIAnimation.PositionX(ActivePackListContainer, fromX, toX, 0.5f);
				anim.style	= UIAnimation.Style.EaseOut;

				anim.Play();

				// Animate the new container onto the screen
				fromX	= (previousBundleIndex > currentBundleIndex) ? -RectT.rect.width : RectT.rect.width;
				toX		= 0;

				anim		= UIAnimation.PositionX(container, fromX, toX, 0.5f);
				anim.style	= UIAnimation.Style.EaseOut;

				anim.OnAnimationFinished += (GameObject obj) => 
				{
					// Re-enable the scroll rect now that the animation as finished
					packListScrollRect.enabled	= true;
					isAnimatingContainers		= false;
				};

				anim.Play();
			}

			ActivePackListContainer = container;
		}

		private void AnimateListOffScreen(RectTransform listContainer)
		{
			float fromX	= 0;
			float toX	= (previousBundleIndex > currentBundleIndex) ? -RectT.rect.width : RectT.rect.width;

			UIAnimation.PositionX(listContainer, fromX, toX, 0.5f).Play();
		}

		private void UpdateBundleHeader(BundleInfo bundleInfo, bool animate)
		{
			// Set the left/right button interactable
			leftBundleButton.interactable	= currentBundleIndex > 0;
			rightBundleButton.interactable	= currentBundleIndex < GameManager.Instance.BundleInfos.Count - 1;

			if (animate)
			{
				UIAnimation.SwapText(bundleText, bundleInfo.BundleName, 0.5f);
			}
			else
			{
				// Just set the text
				bundleText.text = bundleInfo.BundleName;
			}
		}

		private void OnPackItemSelected(int index, object data)
		{
			PackInfo packInfo = (PackInfo)data;

			//if (GameManager.Instance.IsPackLocked(packInfo))
			//{
			//	switch (packInfo.unlockType)
			//	{
			//		case PackUnlockType.Stars:
			//			PopupManager.Instance.Show("pack_locked");
			//			break;
			//		case PackUnlockType.IAP:
			//			#if BBG_IAP
			//			IAPManager.Instance.BuyProduct(packInfo.unlockIAPProductId);
			//			#endif
			//			break;
			//	}
			//}
			//else
			{
				GameEventManager.Instance.SendEvent(GameEventManager.EventId_PackSelected, packInfo);

				ScreenManager.Instance.Show("pack_levels");
			}
		}

		private void OnProductPurchased(string productId)
		{
			// Check if the product was for a pack in the current bundle
			BundleInfo bundleInfo = GameManager.Instance.BundleInfos[currentBundleIndex];

			for (int i = 0; i < bundleInfo.PackInfos.Count; i++)
			{
				if (bundleInfo.PackInfos[i].unlockIAPProductId == productId)
				{
					// The player just purchased a pack so update the ui so it is no longer locked
					UpdateUI(false);

					break;
				}
			}
		}

		#endregion
	}
}
