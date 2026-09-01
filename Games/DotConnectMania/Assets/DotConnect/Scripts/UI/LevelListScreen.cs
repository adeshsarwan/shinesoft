using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BizzyBeeGames.DotConnect
{
	public class LevelListScreen : Screen
	{
		#region Inspector Variables

		[Space]

		[SerializeField] private LevelListItem	levelListItemPrefab	= null;
		[SerializeField] private RectTransform	levelListContainer	= null;
		[SerializeField] private ScrollRect		levelListScrollRect	= null;
		[SerializeField] private Text			packNameText		= null;

		#endregion

		#region Member Variables

		private PackInfo							currentPackInfo;
		private RecyclableListHandler<LevelData>	levelListHandler;

		#endregion

		#region Properties

		#endregion

		#region Unity Methods

		#endregion

		#region Public Methods

		public override void Initialize()
		{
			base.Initialize();

			GameEventManager.Instance.RegisterEventHandler(GameEventManager.EventId_PackSelected, OnPackSelected);
		}

		public override void Show(bool back, bool immediate)
		{
			base.Show(back, immediate);

			if (back)
			{
				levelListHandler.Refresh();
			}
		}
		
		#endregion

		#region Private Methods

		private void OnPackSelected(string eventId, object[] data)
		{
			PackInfo selectedPackInfo = data[0] as PackInfo;

			if (currentPackInfo != selectedPackInfo)
			{
				UpdateList(selectedPackInfo);
			}
		}

		private void UpdateList(PackInfo packInfo)
		{
			currentPackInfo = packInfo;

			packNameText.text = packInfo.packName;
            Debug.Log("Name" + packNameText.text);
            if (packInfo.packName == "EASY PEASY")
            {
                packNameText.text = "EASY";
            }
            else if (packInfo.packName == "NOT SO BAD")
            {
                packNameText.text = "MEDIUM";

            }
            else if (packInfo.packName == "CHALLENGING")
            {
                packNameText.text = "HARD";

            }
            else if (packInfo.packName == "PRETTY HARD")
            {
                packNameText.text = "DIFFICULT";

            }
            else if (packInfo.packName == "VERY DIFFICULT")
            {
                packNameText.text = "ADVANCE";

            }
            else if (packInfo.packName == "IMPOSSIBLE")
            {
                packNameText.text = "EXPERT";

            }
            else
            {
                packInfo.packName = packNameText.text;

            }

            if (levelListHandler == null)
			{
				levelListHandler					= new RecyclableListHandler<LevelData>(packInfo.LevelDatas, levelListItemPrefab, levelListContainer, levelListScrollRect);
				levelListHandler.OnListItemClicked	= OnLevelListItemClicked;
				levelListHandler.Setup();
			}
			else
			{
				levelListHandler.UpdateDataObjects(packInfo.LevelDatas);
			}
		}

		// private void OnLevelListItemClicked(LevelData levelData)
		// {
		// 	if (!GameManager.Instance.IsLevelLocked(levelData))
		// 	{
		// 		GameManager.Instance.StartLevel(currentPackInfo, levelData);
		// 	}
		// }

		private void OnLevelListItemClicked(LevelData levelData)
		{
			GameManager.Instance.RequestPlayLockedLevel(currentPackInfo, levelData);
		}

		#endregion
	}
}
