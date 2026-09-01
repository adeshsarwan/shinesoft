using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace BizzyBeeGames.DotConnect
{
	public class GridCell : MonoBehaviour
	{
		#region Inspector Variables

		[SerializeField] private Image background;
		[SerializeField] private Image block;
		[SerializeField] private Image placed;
		[SerializeField] private Image hint;

		[Header("Line Segment - End Images")]
		[SerializeField] private Image endUnConnected	= null;
		[SerializeField] private Image endTop			= null;
		[SerializeField] private Image endBottom		= null;
		[SerializeField] private Image endLeft			= null;
		[SerializeField] private Image endRight			= null;

		[Header("Line Segment - Straight Images")]
		[SerializeField] private Image straightVertical		= null;
		[SerializeField] private Image straightHorizontal	= null;

		[Header("Line Segment - Unconnected Images")]
		[SerializeField] private Image unconnectedTop		= null;
		[SerializeField] private Image unconnectedBottom	= null;
		[SerializeField] private Image unconnectedLeft		= null;
		[SerializeField] private Image unconnectedRight		= null;

		[Header("Line Segment - Corner Images")]
		[SerializeField] private Image cornerTopLeft		= null;
		[SerializeField] private Image cornerTopRight		= null;
		[SerializeField] private Image cornerBottomLeft		= null;
		[SerializeField] private Image cornerBottomRight	= null;

		[Header("Grid Lines")]
		[SerializeField] private Image topLine		= null;
		[SerializeField] private Image bottomLine	= null;
		[SerializeField] private Image leftLine		= null;
		[SerializeField] private Image rightLine	= null;

		[Header("Borders")]
		[SerializeField] private Image topBorder			= null;
		[SerializeField] private Image bottomBorder			= null;
		[SerializeField] private Image leftBorder			= null;
		[SerializeField] private Image rightBorder			= null;
		[SerializeField] private Image topLeftCorner		= null;
		[SerializeField] private Image topRightCorner		= null;
		[SerializeField] private Image bottomLeftCorner		= null;
		[SerializeField] private Image bottomRightCorner	= null;

		#endregion

		#region Member Variables

		private Color activeColor;

		#endregion

		#region Properties

		public RectTransform RectT { get { return transform as RectTransform; } }

		private List<Image> AllLineSegements
		{
			get
			{
				return new List<Image>()
				{
					endUnConnected,
					endTop,
					endBottom,
					endLeft,
					endRight,
					straightVertical,
					straightHorizontal,
					unconnectedTop,
					unconnectedBottom,
					unconnectedLeft,
					unconnectedRight,
					cornerTopLeft,
					cornerTopRight,
					cornerBottomLeft,
					cornerBottomRight
				};
			}
		}

		#endregion

		#region Public Methods

		public void Setup(bool isBlank, bool isBlock, bool topBlank, bool bottomBlank, bool leftBlank, bool rightBlank)
		{
			background.enabled	= !isBlank;
			block.enabled		= isBlock;
			hint.enabled		= false;

			topBorder.enabled		= !isBlank && topBlank;
			bottomBorder.enabled	= !isBlank && bottomBlank;
			leftBorder.enabled		= !isBlank && leftBlank;
			rightBorder.enabled		= !isBlank && rightBlank;

			topLine.enabled			= !isBlank && !topBlank;
			bottomLine.enabled		= !isBlank && !bottomBlank;
			leftLine.enabled		= !isBlank && !leftBlank;
			rightLine.enabled		= !isBlank && !rightBlank;

			topLeftCorner.enabled		= !isBlank && topBlank && leftBlank;
			topRightCorner.enabled		= !isBlank && topBlank && rightBlank;
			bottomLeftCorner.enabled	= !isBlank && bottomBlank && leftBlank;
			bottomRightCorner.enabled	= !isBlank && bottomBlank && rightBlank;
		}

		public void SetLineSegment(bool isLineEnd, bool top, bool bottom, bool left, bool right)
		{
			endUnConnected.enabled	= isLineEnd && (!top && !bottom && !left && !right);
			endTop.enabled			= isLineEnd && top;
			endBottom.enabled		= isLineEnd && bottom;
			endLeft.enabled			= isLineEnd && left;
			endRight.enabled		= isLineEnd && right;

			straightVertical.enabled	= !isLineEnd && top && bottom;
			straightHorizontal.enabled	= !isLineEnd && left && right;

			unconnectedTop.enabled		= !isLineEnd && top && !bottom && !left && !right;
			unconnectedBottom.enabled	= !isLineEnd && bottom && !top && !left && !right;
			unconnectedLeft.enabled		= !isLineEnd && left && !bottom && !top && !right;
			unconnectedRight.enabled	= !isLineEnd && right && !bottom && !left && !top;

			cornerTopLeft.enabled		= !isLineEnd && top && left;
			cornerTopRight.enabled		= !isLineEnd && top && right;
			cornerBottomLeft.enabled	= !isLineEnd && bottom && left;
			cornerBottomRight.enabled	= !isLineEnd && bottom && right;
		}

		public void SetColor(Color color)
		{
			activeColor = color;

			List<Image> allLineSegments = AllLineSegements;

			for (int i = 0; i < allLineSegments.Count; i++)
			{
				allLineSegments[i].color = color;
			}
		}

		public void SetPlaced(Color placedColor)
		{
			placed.enabled = true;

			placedColor.a	= placed.color.a;
			placed.color	= placedColor;
		}

		public void SetHint(bool isShownForHint)
		{
			hint.enabled = isShownForHint;
		}

		public void ClearLineSegment()
		{
			List<Image> allLineSegments = AllLineSegements;

			for (int i = 0; i < allLineSegments.Count; i++)
			{
				allLineSegments[i].enabled = false;
			}

			placed.enabled = false;
		}

		#endregion

		#region Protected Methods

		#endregion

		#region Private Methods

		#endregion
	}
}
