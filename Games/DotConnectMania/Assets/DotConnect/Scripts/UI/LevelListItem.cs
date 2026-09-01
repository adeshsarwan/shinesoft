using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BizzyBeeGames.DotConnect
{
	public class LevelListItem : RecyclableListItem<LevelData>
	{
		#region Inspector Variables

		[SerializeField] private Text	levelNumberText	= null;
        [SerializeField] private Text levelNumberText1 = null;
        [SerializeField] private Image	starIcon		= null;
		[SerializeField] private Image	completeIcon	= null;
		[SerializeField] private Image	lockedIcon		= null;
		[SerializeField] private Image	playIcon		= null;
		[SerializeField] private Button button			= null; // assign the item's clickable Button in the Inspector

		#endregion

		#region Member Variables

		#endregion

		#region Properties

		#endregion

		#region Unity Methods

		#endregion

		#region Public Methods

		public override void Initialize(LevelData levelData)
		{
		}

		public override void Setup(LevelData levelData)
		{
			levelNumberText.text = (levelData.LevelIndex + 1).ToString();

			HideAllIcons();

			if (GameManager.Instance.HasEarnedStar(levelData))
			{
				SetEarnedStar();
               
            }
			else if (GameManager.Instance.IsLevelCompleted(levelData))
			{
				SetCompleted();
                SetEarnedStar();

            }
			else if (GameManager.Instance.IsLevelLocked(levelData))
			{
				SetLocked();
			}
			else
			{
				SetPlayable();
			}

		}

		public override void Removed()
		{
		}

		#endregion

		#region Private Methods

		private void SetEarnedStar()
		{
			starIcon.enabled = true;
            levelNumberText1.gameObject.SetActive(false);

        }

		private void SetCompleted()
		{
			completeIcon.enabled = true;
            levelNumberText1.gameObject.SetActive(true);

        }

		private void SetLocked()
		{
			lockedIcon.enabled = true;
		}

		private void SetPlayable()
		{
			playIcon.enabled = true;
			//levelNumberText.color = completeIcon.color;
			levelNumberText1.text = levelNumberText.text;
			levelNumberText1.gameObject.SetActive(true);
			
		}

		private void HideAllIcons()
		{
			starIcon.enabled		= false;
			completeIcon.enabled	= false;
			lockedIcon.enabled		= false;
			playIcon.enabled		= false;
		}

		#endregion
	}
}
