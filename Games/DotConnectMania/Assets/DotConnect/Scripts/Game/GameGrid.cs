using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace BizzyBeeGames.DotConnect
{
	public class GameGrid : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IDragHandler
	{
		#region Classes

		public class PlacedLine
		{
			public int								lineIndex			= 0;
			public List<LineCell>					lineSegments		= new List<LineCell>();
			public Dictionary<CellPos, LineCell>	lineSegmentMapping	= new Dictionary<CellPos, LineCell>();

			public LineCell EndCell1 { get { return lineSegments[0]; } }
			public LineCell EndCell2 { get { return lineSegments[lineSegments.Count - 1]; } }

			private bool hasChanged = false;

			public PlacedLine(int lineIndex)
			{
				this.lineIndex = lineIndex;
			}

			public void InsertLineSegment(int index, LineCell lineCell)
			{
				hasChanged = true;

				lineSegments.Insert(index, lineCell);
				lineSegmentMapping[lineCell.cellPos] = lineCell;
			}

			public void RemoveLineSegmentAt(int index)
			{
				hasChanged = true;

				lineSegmentMapping.Remove(lineSegments[index].cellPos);
				lineSegments.RemoveAt(index);
			}

			public void RemoveLineSegmentRange(int startIndex, int length)
			{
				for (int i = 0; i < length && startIndex < lineSegments.Count; i++)
				{
					RemoveLineSegmentAt(startIndex);
				}
			}

			public void Clear()
			{
				if (lineSegments.Count > 2)
				{
					RemoveLineSegmentRange(1, lineSegments.Count - 2);
				}

				EndCell1.isEndConnected = false;
				EndCell2.isEndConnected = false;
			}

			public bool HasChanged()
			{
				if (hasChanged)
				{
					hasChanged = false;

					return true;
				}

				return false;
			}
		}

		public class LineCell
		{
			public CellPos	cellPos;
			public int		lineIndex;
			public bool		isEnd;
			public bool		isEndConnected;
			public bool		isCut;

			public LineCell(int row, int col, int lineIndex)
			{
				this.cellPos	= new CellPos(row, col);
				this.lineIndex	= lineIndex;
			}
		}

		private class Cell
		{
			public GridCell gridCell;
			public LineCell lineCell;
		}

		#endregion

		#region Enums

		private enum DrawState
		{
			None,
			Active,
			Disabled
		}

		private enum ConnectedDirection
		{
			None,
			Top,
			Right,
			Bottom,
			Left
		}

		#endregion

		#region Inspector Variables

		[SerializeField] private RectTransform	gridContainer	= null;
		[SerializeField] private GridCell		gridCellPrefab	= null;
		[SerializeField] private List<Color>	lineColors		= new List<Color>() { Color.gray };
		[SerializeField] private Image			cursorImage		= null;
 		[Space]
		[SerializeField] private Text			moveAmountText	= null;
		[SerializeField] private Text			lineAmountText	= null;
		[SerializeField] private Text			fillAmountText	= null;
		[SerializeField] private Button			undoButton		= null;

		#endregion

		#region Member Variables

		private ObjectPool				gridCellPool;

		private LevelData				currentLevelData;
		private LevelSaveData			currentLevelSaveData;
		private float					currentCellSize;
		private List<List<Cell>>		grid;
		private List<PlacedLine>		placedLines;
		private int						totalBlankCells;

		private bool					isPointerActive;
		private int						activePointerId;
		private DrawState				drawState;
		private int						lastChangedLineIndex;
		private int						activeLineIndex;
		private CellPos					lastCellPos;

		#endregion

		#region Properties

		private PlacedLine ActivePlacedLine { get { return activeLineIndex >= 0 && activeLineIndex < placedLines.Count ? placedLines[activeLineIndex] : null; } }

		#endregion

		#region Public Variables

		public void Initialize()
		{
			gridCellPool = new ObjectPool(gridCellPrefab.gameObject, 9, gridContainer);
		}

		public void SetupLevel(LevelData levelData, LevelSaveData levelSaveData)
		{
			// Clear the grid
			gridCellPool.ReturnAllObjectsToPool();

			lastChangedLineIndex	= -1;
			activeLineIndex			= -1;

			// Assign the LevelData that is currently being displayed/played
			currentLevelData		= levelData;
			currentLevelSaveData	= levelSaveData;

			// Setup an empty grid with all the initial cell images
			SetupGrid(levelData);

			// Setup the list of GridLines for this level
			SetupLines(levelData);

			// Set the placed line positions
			if (currentLevelSaveData.placedLineSegments == null)
			{
				currentLevelSaveData.placedLineSegments = GetPlacedLineSegmentCellPositions();
			}
			else
			{
				// Load the saved line positions
				CreateLineCells(currentLevelSaveData.placedLineSegments);
			}

			// Draw the inital lines
			DrawLines();

			// If there is a saved undo then set the undo button to interactable
			undoButton.interactable = (currentLevelData.undoPlacedLineSegments != null);

			// Reset variables 
			SetNumMoves(currentLevelSaveData.numMoves);
			UpdateFillText();
			UpdateLinesText();
		}

		public void OnPointerDown(PointerEventData eventData)
		{
			//Debug.LogFormat("OnPointerDown\nisPointerActive: {0}\nactiveLineIndex: {1}\ndrawState: {2}", isPointerActive, activeLineIndex, drawState);

			// If there is already an active pointer then ignore this event
			if (isPointerActive)
			{
				return;
			}

			isPointerActive = true;
			activePointerId = eventData.pointerId;

			HandleNewMousePosition(eventData.position);

			// If there is an active line show the cursor and set it's color to the active lines color
			if (activeLineIndex != -1)
			{
				Color color			= GetLineColor(activeLineIndex);
				color.a				= 0.5f;
				cursorImage.color	= color;
				cursorImage.enabled	= true;

				PositionCursor(eventData.position);
			}

			if (ActivePlacedLine.HasChanged())
			{
				SoundManager.Instance.Play("tile-placed");
			}
		}

		public void OnPointerUp(PointerEventData eventData)
		{
			//Debug.LogFormat("OnPointerUp\nisPointerActive: {0}\nactiveLineIndex: {1}\ndrawState: {2}", isPointerActive, activeLineIndex, drawState);

			// Hide the cursor if it was visible
			cursorImage.enabled	= false;

			// If the event is not for the active down pointer then ignore this event
			if (!isPointerActive || activePointerId != eventData.pointerId || activeLineIndex == -1)
			{
				isPointerActive		= false;
				drawState			= DrawState.None;
				activeLineIndex		= -1;
				lastCellPos			= null;

				return;
			}

			// Clear any line segments from placed lines that are cut by the active placed line
			ClearLineCuts();

			List<List<CellPos>> lastPlacedLineSegments		= currentLevelSaveData.placedLineSegments;
			List<List<CellPos>> currentPlacedLineSegments	= GetPlacedLineSegmentCellPositions();

			// Check if the active placed line changed
			List<CellPos> lastActiveLineCellPositions	= lastPlacedLineSegments[activeLineIndex];
			List<CellPos> curActiveLineCellPositions	= currentPlacedLineSegments[activeLineIndex];

			bool lineChanged = CheckLineChanged(lastActiveLineCellPositions, curActiveLineCellPositions);

			// Check if the line changed on the board
			if (lineChanged)
			{
				currentLevelSaveData.placedLineSegments		= currentPlacedLineSegments;
				currentLevelData.undoPlacedLineSegments		= lastPlacedLineSegments;
				currentLevelData.undoNumMoves				= currentLevelSaveData.numMoves;
				currentLevelData.undoLastChangedLineIndex	= lastChangedLineIndex;

				// Set the Undo button clickable
				undoButton.interactable = true;

				// Check if the changed line is differenct then the last line that was changed
				if (activeLineIndex != lastChangedLineIndex)
				{
					// increment the number of moves
					SetNumMoves(currentLevelSaveData.numMoves + 1);
				}

				lastChangedLineIndex = activeLineIndex;
			}

			// Make sure all line segments that can be connected are connected
			CheckForLineConnections();

			isPointerActive		= false;
			drawState			= DrawState.None;
			activeLineIndex		= -1;
			lastCellPos			= null;

			// Re-draw the lines
			DrawLines();

			// Check if the level is now complete
			if (CheckLevelComplete())
			{
				GameEventManager.Instance.SendEvent(GameEventManager.EventId_ActiveLevelCompleted, currentLevelSaveData.numMoves);
				//LevelStats.instance.UpdateLevelPlayed("", currentLevelData.LevelIndex + 1);
			}

			UpdateLinesText();
			UpdateFillText();
		}

		public void OnDrag(PointerEventData eventData)
		{
			// If the event is not for the active down pointer then ignore this event
			if (!isPointerActive || activePointerId != eventData.pointerId)
			{
				return;
			}

			HandleNewMousePosition(eventData.position);

			UpdateFillText();

			PositionCursor(eventData.position);

			if (ActivePlacedLine.HasChanged())
			{
				SoundManager.Instance.Play("tile-placed");
			}
		}

		public void UndoLastMove()
		{
			if (isPointerActive) return;

			CreateLineCells(currentLevelData.undoPlacedLineSegments);

			currentLevelSaveData.placedLineSegments		= currentLevelData.undoPlacedLineSegments;
			currentLevelData.undoPlacedLineSegments		= null;

			undoButton.interactable = false;
			SetNumMoves(currentLevelData.undoNumMoves);

			lastChangedLineIndex = currentLevelData.undoLastChangedLineIndex;
			UpdateFillText();
			UpdateLinesText();
			DrawLines();
		}

		/// <summary>
		/// Clears the board of all player placed line segments, re-places any lines that where shown because of a hint beingused
		/// </summary>
		public void ResetBoard()
		{
			if (isPointerActive) return;

			// Clear all line segments leaving only the dots
			ClearAllLineSegments();
			ResetGridCells();

			// Show all the lines which were shown because a hint was used
			for (int i = 0; i < currentLevelSaveData.hintLineIndices.Count; i++)
			{
				int lineIndex = currentLevelSaveData.hintLineIndices[i];

				ShowLineForHint(placedLines[lineIndex]);
			}

			currentLevelSaveData.placedLineSegments		= GetPlacedLineSegmentCellPositions();
			currentLevelData.undoPlacedLineSegments		= null;

			lastChangedLineIndex = -1;

			undoButton.interactable = false;

			DrawLines();

			UpdateLinesText();
			UpdateFillText();
			SetNumMoves(currentLevelSaveData.hintLineIndices.Count);
 		}

		public void ShowHint()
		{
			if (isPointerActive) return;

			// Get all un-connected lines
			List<PlacedLine> unconnectedLines = new List<PlacedLine>();

			for (int i = 0; i < placedLines.Count; i++)
			{
				PlacedLine placedLine = placedLines[i];

				if (!placedLine.EndCell1.isEndConnected || !placedLine.EndCell2.isEndConnected)
				{
					unconnectedLines.Add(placedLine);
				}
			}

			PlacedLine placedLineToConnect = null;

			// Get a random unconnected PlacedLine to connect
			if (unconnectedLines.Count > 0)
			{
				placedLineToConnect = unconnectedLines[Random.Range(0, unconnectedLines.Count)];
			}
			// If all lines are connected then pick a random line to connect properly
			else
			{
				placedLineToConnect = placedLines[Random.Range(0, placedLines.Count)];
			}

			// Get the line index of the line we are about to show
			int lineIndex = placedLineToConnect.lineIndex;

			ShowLineForHint(placedLineToConnect);

			CheckForLineConnections();

			// Update the level data with the new placed line
			currentLevelData.undoPlacedLineSegments		= currentLevelSaveData.placedLineSegments;
			currentLevelData.undoNumMoves				= currentLevelSaveData.numMoves;
			currentLevelData.undoLastChangedLineIndex	= lastChangedLineIndex;
			currentLevelSaveData.placedLineSegments		= GetPlacedLineSegmentCellPositions();

			// Set the Undo button clickable
			undoButton.interactable = true;

			// Set the last changed line index
			lastChangedLineIndex = lineIndex;

			// Add the line index that was shown as a hint so when the board is reset the hint will re-appear
			currentLevelSaveData.hintLineIndices.Add(lineIndex);

			// Re-draw the lines
			DrawLines();

			// Increment the number of moves
			SetNumMoves(currentLevelSaveData.numMoves + 1);

			// Check if the level is now complete
			if (CheckLevelComplete())
			{
				GameEventManager.Instance.SendEvent(GameEventManager.EventId_ActiveLevelCompleted, currentLevelSaveData.numMoves);
				//LevelStats.instance.UpdateLevelPlayed("", currentLevelData.LevelIndex + 1);
			}

			UpdateLinesText();
			UpdateFillText();
		}

		#endregion

		#region Private Variables

		#region Setup Methods

		/// <summary>
		/// Sets up the intial layout of the grid with all the needed cell images
		/// </summary>
		private void SetupGrid(LevelData levelData)
		{
			currentCellSize = Mathf.Min(gridContainer.rect.width / (float)levelData.GridCols, gridContainer.rect.height / (float)levelData.GridRows);

			float totalCellWidth	= levelData.GridCols * currentCellSize;
			float totalCellHeight	= levelData.GridRows * currentCellSize;

			grid = new List<List<Cell>>();

			for (int r = 0; r < levelData.GridRows; r++)
			{
				grid.Add(new List<Cell>());

				for (int c = 0; c < levelData.GridCols; c++)
				{
					GridCell gridCell = gridCellPool.GetObject<GridCell>();

					float xPos 	= c * currentCellSize - totalCellWidth / 2f + currentCellSize / 2f;
					float yPos 	= -r * currentCellSize + totalCellHeight / 2f - currentCellSize / 2f;
					float scale	= currentCellSize / Mathf.Max(gridCell.RectT.rect.width, gridCell.RectT.rect.height);

					gridCell.transform.localScale	= new Vector3(scale, scale, 1f);
					gridCell.RectT.anchoredPosition	= new Vector2(xPos, yPos);

					bool isBlock = levelData.GridCells[r][c] == 1;
					bool isBlank = levelData.GridCells[r][c] == 2;

					bool topBlank		= r == 0 || levelData.GridCells[r - 1][c] == 2;
					bool bottomBlank	= r == levelData.GridRows - 1 || levelData.GridCells[r + 1][c] == 2;
					bool leftBlank		= c == 0 || levelData.GridCells[r][c - 1] == 2;
					bool rightBlank		= c == levelData.GridCols - 1 || levelData.GridCells[r][c + 1] == 2;

					gridCell.Setup(isBlank, isBlock, topBlank, bottomBlank, leftBlank, rightBlank);

					Cell cell = new Cell();

					cell.gridCell = gridCell;

					ClearLineSegment(cell);

					grid[r].Add(cell);
				}
			}
		}

		/// <summary>
		/// Creates the placedLines list and adds the end points
		/// </summary>
		private void SetupLines(LevelData levelData)
		{
			placedLines = new List<PlacedLine>();

			totalBlankCells = 0;

			for (int i = 0; i < levelData.LinePositions.Count; i++)
			{
				// The line coordinate for each line is sorted from beginning to end so the end points are at the beginning and end of the list
				List<CellPos> line = levelData.LinePositions[i];

				// Get the end point positions
				CellPos endPoint1 = line[0];
				CellPos endPoint2 = line[line.Count - 1];

				LineCell endLineCell1	= new LineCell(endPoint1.row, endPoint1.col, i);
				endLineCell1.isEnd		= true;

				LineCell endLineCell2	= new LineCell(endPoint2.row, endPoint2.col, i);
				endLineCell2.isEnd		= true;

				// Create the placed line
				PlacedLine placedLine = new PlacedLine(i);

				placedLine.lineSegments.Add(endLineCell1);
				placedLine.lineSegments.Add(endLineCell2);

				placedLines.Add(placedLine);

				totalBlankCells += line.Count - 2;

				bool showHint = currentLevelSaveData.hintLineIndices.Contains(i);

				grid[endPoint1.row][endPoint1.col].gridCell.SetHint(showHint);
				grid[endPoint2.row][endPoint2.col].gridCell.SetHint(showHint);
			}
		}

		#endregion

		#region Update Methods

		/// <summary>
		/// Handles taking the new position of the mouse on the screen and adjusting the game board based on that new position
		/// </summary>
		private void HandleNewMousePosition(Vector2 screenPosition)
		{
			CellPos cellPos;

			// Update the active line
			if (GetCellPos(screenPosition, out cellPos))
			{
				// If the cell pos has not changed from the last active cell pos then just return now
				if (cellPos.Equals(lastCellPos))
				{
					return;
				}

				lastCellPos = cellPos;

				switch (drawState)
				{
					case DrawState.None:
						HandleNoneDrawState(cellPos);
						break;
					case DrawState.Active:
						HandleActiveDrawState(cellPos);
						UpdateActiveLineCuts();
						break;
				}
			}

			// Update the list of gridCells by re-drawing all the lines
			DrawLines();
		}

		/// <summary>
		/// Gets the row/col that the given screen position is over. Returns false if it's not over any cell.
		/// </summary>
		private bool GetCellPos(Vector2 screenPosition, out CellPos cellPos)
		{
			Vector2 localPosition;

			RectTransformUtility.ScreenPointToLocalPointInRectangle(gridContainer, screenPosition, null, out localPosition);

			float xCellsFromMiddle = localPosition.x / currentCellSize;
			float yCellsFromMiddle = -localPosition.y / currentCellSize;

			int row = Mathf.FloorToInt(((float)currentLevelData.GridRows / 2f) + yCellsFromMiddle);
			int col = Mathf.FloorToInt(((float)currentLevelData.GridCols / 2f) + xCellsFromMiddle);

			if (row < 0 || row >= currentLevelData.GridRows || col < 0 || col >= currentLevelData.GridCols)
			{
				cellPos = null;

				return false;
			}

			cellPos = new CellPos(row, col);

			return true;
		}

		private void HandleNoneDrawState(CellPos cellPos)
		{
			LineCell lineCell = grid[cellPos.row][cellPos.col].lineCell;

			// Try and get the line cell for this cell position
			if (lineCell != null)
			{
				drawState		= DrawState.Active;
				activeLineIndex	= lineCell.lineIndex;

				PlacedLine activePlacedLine = ActivePlacedLine;

				if (lineCell.isEnd)
				{
					// If the cell is an end cell and the line has more than 2 cells then clear all the none end cells
					if (activePlacedLine.lineSegments.Count > 2)
					{
						activePlacedLine.RemoveLineSegmentRange(1, activePlacedLine.lineSegments.Count - 2);
					}

					// Check if the lineCell is at the front of line segments and if not move it there
					if (lineCell != activePlacedLine.lineSegments[0])
					{
						activePlacedLine.lineSegments[1] = activePlacedLine.lineSegments[0];
						activePlacedLine.lineSegments[0] = lineCell;
					}

					activePlacedLine.EndCell1.isEndConnected = true;
					activePlacedLine.EndCell2.isEndConnected = false;
				}
				else
				{
					// Else if it's a line segments, find the longest path that leads to end end point
					ClearUnconnectedOrShortestPath(lineCell);
				}
			}
			else
			{
				// Disable any drawing until a new down event
				drawState = DrawState.Disabled;
			}
		}

		/// <summary>
		/// Handles drawing line segemnts from the active cell pos to the given cellPos. Returns true if the line is connected.
		/// </summary>
		private void HandleActiveDrawState(CellPos cellPos)
		{
			PlacedLine	activePlacedLine	= ActivePlacedLine;
			LineCell	moveToLineCell		= grid[cellPos.row][cellPos.col].lineCell;

			if (moveToLineCell != null && moveToLineCell.lineIndex == activeLineIndex && moveToLineCell != activePlacedLine.EndCell2)
			{
				// Make sure end cell 2 is no longer connected, this will also make is so it clears the correct path
				activePlacedLine.EndCell2.isEndConnected = false;

				// Clear all the line segments up to this cell
				ClearUnconnectedOrShortestPath(moveToLineCell);

				return;
			}

			// Get the active PlacedLine
			LineCell lastLineCell = activePlacedLine.lineSegments[activePlacedLine.lineSegments.Count - 2];

			// Try and move to the cell
			MoveToNextCellPos(lastLineCell.cellPos, cellPos, activeLineIndex);

			// Update the last cell pos because it might have changed
			lastLineCell = activePlacedLine.lineSegments[activePlacedLine.lineSegments.Count - 2];

			// Check if the move to cellPos is the second end cell and the cell we just moved to is adjacent to it then we have connected the line
			if (cellPos.Equals(activePlacedLine.EndCell2.cellPos) && AreCellsAdjacent(lastLineCell.cellPos, cellPos))
			{
				activePlacedLine.EndCell2.isEndConnected = true;
			}
			else
			{
				activePlacedLine.EndCell2.isEndConnected = false;
			}
		}

		/// <summary>
		/// Recursively moves one cell at a time until we cannot move anymore or we have reached the toPos. Adds line segments to the given lineIndex as we move.
		/// </summary>
		private void MoveToNextCellPos(CellPos fromPos, CellPos toPos, int lineIndex)
		{
			int rowDiff = toPos.row - fromPos.row;
			int colDiff = toPos.col - fromPos.col;
			int rowDist = Mathf.Abs(rowDiff);
			int colDist = Mathf.Abs(colDiff);

			int nextRow;
			int nextCol;

			bool canMoveRow = rowDiff != 0 && CanMove(fromPos, rowDiff > 0 ? 1 : -1, 0);
			bool canMoveCol = colDiff != 0 && CanMove(fromPos, 0, colDiff > 0 ? 1 : -1);

			if (canMoveRow && (rowDist > colDist || !canMoveCol))
			{
				nextRow = fromPos.row + (rowDiff > 0 ? 1 : -1);
				nextCol = fromPos.col;
			}
			else if (canMoveCol)
			{
				nextRow = fromPos.row;
				nextCol = fromPos.col + (colDiff > 0 ? 1 : -1);
			}
			else
			{
				// Could not move to any new position, return
				return;
			}

			Cell moveToGridCell	= grid[nextRow][nextCol];
			LineCell moveToLineCell	= moveToGridCell.lineCell;

			// Check if the cell we are moving to is occupied by a line segment from the same line we are drawing
			// If so, we need re remove all line segments in the placed line up to this line segment
			if (moveToLineCell != null && moveToLineCell.lineIndex == lineIndex)
			{
				ClearUnconnectedOrShortestPath(moveToLineCell);
			}
			else
			{
				// Else create a new line cell
				moveToLineCell = new LineCell(nextRow, nextCol, lineIndex);

				// Add the new line cell to the list of line segments
				ActivePlacedLine.InsertLineSegment(ActivePlacedLine.lineSegments.Count - 1, moveToLineCell);
			}

			CellPos nextPos = moveToLineCell.cellPos;

			// Check if we have reached the toPos cell
			if (nextPos.Equals(toPos))
			{
				return;
			}

			// Try and move to another cell
			MoveToNextCellPos(nextPos, toPos, lineIndex);
		}

		/// <summary>
		/// Clears the part of the lin segment starting frmo the given line cell that is not connected to an end. If both ends are connected
		/// then this clears the shorest path from the given line cell.
		/// </summary>
		private void ClearUnconnectedOrShortestPath(LineCell lineCell, bool clearLineCellAlso = false)
		{
			PlacedLine placedLine = placedLines[lineCell.lineIndex];

			int index = 0;

			// Get the index of the LineCell in the PlaceLine
			for (int i = 0; i < placedLine.lineSegments.Count; i++)
			{
				if (lineCell == placedLine.lineSegments[i])
				{
					index = i;

					break;
				}
			}

			// Check if the last line segment is connected to the second end cell
			if (placedLine.EndCell2.isEndConnected && index < Mathf.FloorToInt(placedLine.lineSegments.Count / 2f))
			{
				index = placedLine.lineSegments.Count - index - 1;

				// Reverse the list
				placedLine.lineSegments.Reverse();
			}

			placedLine.EndCell2.isEndConnected = false;

			if (!clearLineCellAlso)
			{
				index += 1;
			}

			while (index < placedLine.lineSegments.Count - 1)
			{
				LineCell lineSegmentCell = placedLine.lineSegments[index];

				// Set the lineCell on the GridCell as blank now or it will mess up other things
				grid[lineSegmentCell.cellPos.row][lineSegmentCell.cellPos.col].lineCell = null;

				// Remove the LineCell from the line
				placedLine.RemoveLineSegmentAt(index);
			}
		}

		/// <summary>
		/// Updates which LineCells from other lines are intercepted by the current active line
		/// </summary>
		private void UpdateActiveLineCuts()
		{
			for (int i = 0; i < placedLines.Count; i++)
			{
				if (i == activeLineIndex)
				{
					continue;
				}

				PlacedLine	placedLine	= placedLines[i];
				List<int>	cutIndices	= new List<int>();

				for (int j = 1; j < placedLine.lineSegments.Count - 1; j++)
				{
					LineCell lineCell = placedLine.lineSegments[j];

					if (ActivePlacedLine.lineSegmentMapping.ContainsKey(lineCell.cellPos))
					{
						cutIndices.Add(j);
					}
				}

				int cutFromIndex	= 0;
				int cutToIndex		= 0;
				int halfIndex		= Mathf.FloorToInt(placedLine.lineSegments.Count / 2);
				int lineStartIndex	= 1;
				int lineEndIndex	= placedLine.lineSegments.Count - 2;

				if (cutIndices.Count > 0)
				{
					if (cutIndices.Count == 1)
					{
						if (!placedLine.EndCell2.isEndConnected || cutIndices[0] >= halfIndex)
						{
							//Debug.Log("Here1");
							cutFromIndex	= cutIndices[0];
							cutToIndex		= lineEndIndex;
						}
						else
						{
							//Debug.Log("Here2");
							cutFromIndex	= lineStartIndex;
							cutToIndex		= cutIndices[0];
						}
					}
					else
					{
						if (!placedLine.EndCell2.isEndConnected || cutIndices[0] >= placedLine.lineSegments.Count - cutIndices[cutIndices.Count - 1] - 1)
						{
							//Debug.Log("Here3");
							cutFromIndex	= cutIndices[0];
							cutToIndex		= lineEndIndex;
						}
						else
						{
							//Debug.Log("Here4");
							cutFromIndex	= lineStartIndex;
							cutToIndex		= cutIndices[cutIndices.Count - 1];
						}
					}
				}

				for (int j = 1; j < placedLine.lineSegments.Count - 1; j++)
				{
					placedLine.lineSegments[j].isCut = (j >= cutFromIndex && j <= cutToIndex);
				}
			}
		}

		/// <summary>
		/// Removes any line segments which have isCut set to true
		/// </summary>
		private void ClearLineCuts()
		{
			for (int i = 0; i < placedLines.Count; i++)
			{
				if (i == activeLineIndex)
				{
					continue;
				}

				PlacedLine	placedLine		= placedLines[i];
				bool		beginningCut	= false;
				bool		wasCut			= false;

				for (int j = 1; j < placedLine.lineSegments.Count - 1; j++)
				{
					LineCell lineCell = placedLine.lineSegments[j];

					if (lineCell.isCut)
					{
						wasCut = true;

						placedLine.RemoveLineSegmentAt(j);

						if (j == 1)
						{
							beginningCut = true;
						}

						j--;
					}
				}

				// If the line segment was cut then we need to update it's end cell connections since the line cannt be connected anymore
				if (wasCut)
				{
					// If the line segments list only contains the two end segments then set them both to not connected
					if (placedLine.lineSegments.Count <= 2)
					{
						placedLine.EndCell1.isEndConnected = false;
						placedLine.EndCell2.isEndConnected = false;
					}
					// Check if the very first line segment was cut, if so and there are more than 2 line segments then reverse the placed lineSegments so the connected dot is at the beginning
					else if (beginningCut)
					{
						// If not then reverse the line segments list so the connected dot is at the beginning
						placedLine.EndCell1.isEndConnected = false;
						placedLine.lineSegments.Reverse();
					}
					else
					{
						// Else the line was cut and the first dot is still connected to the last dot must not be connected anymore
						placedLine.EndCell2.isEndConnected = false;
					}
				}
			}
		}

		/// <summary>
		/// Gets the list of cell positions for all the placed lines
		/// </summary>
		private List<List<CellPos>> GetPlacedLineSegmentCellPositions()
		{
			List<List<CellPos>> placedLineSegmentCellPositions = new List<List<CellPos>>(placedLines.Count);

			for (int i = 0; i < placedLines.Count; i++)
			{
				PlacedLine placedLine = placedLines[i];

				placedLineSegmentCellPositions.Add(new List<CellPos>());

				for (int j = 0; j < placedLine.lineSegments.Count; j++)
				{
					placedLineSegmentCellPositions[i].Add(placedLine.lineSegments[j].cellPos);
				}
			}

			return placedLineSegmentCellPositions;
		}

		/// <summary>
		/// Checks if the two lines occupy the same cells
		/// </summary>
		private bool CheckLineChanged(List<CellPos> linePositions1, List<CellPos> linePositions2)
		{
			if (linePositions1.Count != linePositions2.Count)
			{
				return true;
			}

			bool sameForward	= true;
			bool sameBackward	= true;

			for (int i = 0; i < linePositions1.Count; i++)
			{
				CellPos cellPos1a	= linePositions1[i];
				CellPos cellPos1b	= linePositions1[linePositions1.Count - 1 - i];
				CellPos cellPos2	= linePositions2[i];

				if (!cellPos1a.Equals(cellPos2))
				{
					sameForward = false;
				}

				if (!cellPos1b.Equals(cellPos2))
				{
					sameBackward = false;
				}

				if (!sameForward && !sameBackward)
				{
					return true;
				}
			}

			return false;
		}

		/// <summary>
		/// Checks if the line can move from the given fromPos in the direction specified by rowInc/colInc
		/// </summary>
		private bool CanMove(CellPos fromPos, int rowInc, int colInc)
		{
			int row = fromPos.row + rowInc;
			int col = fromPos.col + colInc;

			if (currentLevelData.GridCells[row][col] != 0)
			{
				return false;
			}

			Cell gridCell = grid[row][col];

			return gridCell.lineCell == null || !gridCell.lineCell.isEnd;
		}

		/// <summary>
		/// Checks if the two cells are adjacent
		/// </summary>
		private bool AreCellsAdjacent(CellPos cellPos1, CellPos cellPos2)
		{
			int rowDist = Mathf.Abs(cellPos1.row - cellPos2.row);
			int colDist = Mathf.Abs(cellPos1.col - cellPos2.col);

			return (rowDist == 0 && colDist == 1) || (rowDist == 1 && colDist == 0);
		}

		/// <summary>
		/// Checks if all the lines are connected and all the spaces on the grid have a line segment in them
		/// </summary>
		private bool CheckLevelComplete()
		{
			// Check all the lines are connected to both end points
			for (int i = 0; i < placedLines.Count; i++)
			{
				PlacedLine placedLine = placedLines[i];

				if (!placedLine.EndCell1.isEndConnected || !placedLine.EndCell2.isEndConnected)
				{
					// This line is not connected
					return false;
				}
			}

			// Check id all non blank/block cells have a line segment on them
			for (int r = 0; r < grid.Count; r++)
			{
				for (int c = 0; c < grid[r].Count; c++)
				{
					bool isBlockOrBlank = currentLevelData.GridCells[r][c] != 0;

					// If the cell type is not a blank or block cell and the cell does not have a line segment on it then the board is not complete
					if (!isBlockOrBlank && grid[r][c].lineCell == null)
					{
						return false;
					}
				}
			}

			// This level is complete
			return true;
		}

		/// <summary>
		/// Checks all PlaceLines for end line segments that are beside the end connection and connects them if they are not connected
		/// </summary>
		private void CheckForLineConnections()
		{
			for (int i = 0; i < placedLines.Count; i++)
			{
				PlacedLine placedLine = placedLines[i];

				if (placedLine.lineSegments.Count > 2)
				{
					CellPos lastSegmentPos = placedLine.lineSegments[placedLine.lineSegments.Count - 2].cellPos;

					if (AreCellsAdjacent(lastSegmentPos, placedLine.EndCell2.cellPos))
					{
						placedLine.EndCell2.isEndConnected = true;
					}
				}
			}
		}

		private void ShowLineForHint(PlacedLine lineToShow)
		{
			int lineIndex = lineToShow.lineIndex;

			// Get the cell positions for the line
			List<CellPos> lineCellPositions	= currentLevelData.LinePositions[lineIndex];

			// Clear any current line segemnts
			lineToShow.Clear();

			// Make sure the end cells are in the correct order
			if (!lineToShow.lineSegments[0].cellPos.Equals(lineCellPositions[0]))
			{
				LineCell lineCell = lineToShow.lineSegments[0];

				lineToShow.lineSegments[0] = lineToShow.lineSegments[1];
				lineToShow.lineSegments[1] = lineCell;
			}

			// Create a LineCell for each of the line segements
			for (int i = 1; i < lineCellPositions.Count - 1; i++)
			{
				CellPos		cellPos		= lineCellPositions[i];
				LineCell	curLineCell	= grid[cellPos.row][cellPos.col].lineCell;

				// Check if there is already another line occupying the cell
				if (curLineCell != null && curLineCell.lineIndex != lineIndex)
				{
					// Clear the line
					ClearUnconnectedOrShortestPath(curLineCell, true);
				}

				lineToShow.InsertLineSegment(i, new LineCell(cellPos.row, cellPos.col, lineIndex));
			}

			// Set the two end cells as connected
			lineToShow.EndCell1.isEndConnected = true;
			lineToShow.EndCell2.isEndConnected = true;

			// Show the hint icon on both end cells
			grid[lineToShow.EndCell1.cellPos.row][lineToShow.EndCell1.cellPos.col].gridCell.SetHint(true);
			grid[lineToShow.EndCell2.cellPos.row][lineToShow.EndCell2.cellPos.col].gridCell.SetHint(true);
		}

		private void PositionCursor(Vector2 screenPosition)
		{
			Vector2 localPosition;

			RectTransformUtility.ScreenPointToLocalPointInRectangle(gridContainer, screenPosition, null, out localPosition);

			(cursorImage.transform as RectTransform).anchoredPosition = localPosition;
		}

		#endregion

		#region Draw Methods

		/// <summary>
		/// Draws all the lines on the grid by reseting all the GridCells then looping through each placedLine and setting their GridCell
		/// </summary>
		private void DrawLines()
		{
			// Reset the grid
			ResetGridCells();

			// First draw the active line if there is one
			if (ActivePlacedLine != null)
			{
				DrawLine(ActivePlacedLine);
			}

			// Draw each line
			for (int i = 0; i < placedLines.Count; i++)
			{
				if (i != activeLineIndex)
				{
					DrawLine(placedLines[i]);
				}
			}
		}

		/// <summary>
		/// Draws the placed line by setting the GridCells the line segments are on
		/// </summary>
		private void DrawLine(PlacedLine placedLine)
		{
			bool drawPlacedImages = (activeLineIndex != placedLine.lineIndex && placedLine.lineSegments.Count > 2);

			DrawLineEndPoint(placedLine, placedLine.EndCell1, (placedLine.lineSegments.Count > 2) ? placedLine.lineSegments[1] : null, drawPlacedImages);
			DrawLineEndPoint(placedLine, placedLine.EndCell2, (placedLine.lineSegments.Count > 2) ? placedLine.lineSegments[placedLine.lineSegments.Count - 2] : null, drawPlacedImages && placedLine.EndCell2.isEndConnected);

			for (int i = 1; i < placedLine.lineSegments.Count - 1; i++)
			{
				DrawLineSegment(placedLine, i, drawPlacedImages);
			}
		}

		/// <summary>
		/// Draws the end point for the given line
		/// </summary>
		private void DrawLineEndPoint(PlacedLine placedLine, LineCell endCell, LineCell lineSegmentCell, bool drawPlacedImages)
		{
			// Get the connection between this end dot and the line segment
			ConnectedDirection connectedDirection = ConnectedDirection.None;

			if (endCell.isEndConnected && lineSegmentCell != null && !lineSegmentCell.isCut)
			{
				connectedDirection = GetConnectionDirection(endCell.cellPos, lineSegmentCell.cellPos);
			}

			Cell	cell		= grid[endCell.cellPos.row][endCell.cellPos.col];
			Color	lineColor	= GetLineColor(endCell.lineIndex);

			cell.lineCell = endCell;

			// Set the grid cell to draw the end line segment
			cell.gridCell.SetLineSegment(
				true,
				connectedDirection == ConnectedDirection.Top,
				connectedDirection == ConnectedDirection.Bottom,
				connectedDirection == ConnectedDirection.Left,
				connectedDirection == ConnectedDirection.Right);

			cell.gridCell.SetColor(lineColor);

			if (drawPlacedImages)
			{
				cell.gridCell.SetPlaced(lineColor);
			}
		}

		/// <summary>
		/// Draws the line segment for the given line
		/// </summary>
		private void DrawLineSegment(PlacedLine placedLine, int segmentIndex, bool drawPlacedImages)
		{
			LineCell 	lineCell	= placedLine.lineSegments[segmentIndex];
			Cell		cell		= grid[lineCell.cellPos.row][lineCell.cellPos.col];
			Color		lineColor	= GetLineColor(lineCell.lineIndex);

			if (!lineCell.isCut)
			{
				ConnectedDirection connectedDirection1 = GetConnectionDirection(placedLine, lineCell, segmentIndex - 1);
				ConnectedDirection connectedDirection2 = GetConnectionDirection(placedLine, lineCell, segmentIndex + 1);

				// The only way the connection directions can be the same is if there is only one line segment. Both calls to GetConnectionDirection will return
				// a connection to the end point so set the second connection direction to None
				if (connectedDirection1 == connectedDirection2)
				{
					connectedDirection2 = ConnectedDirection.None;
				}

				cell.lineCell = lineCell;

				cell.gridCell.SetLineSegment(
					false,
					(connectedDirection1 == ConnectedDirection.Top || connectedDirection2 == ConnectedDirection.Top),
					(connectedDirection1 == ConnectedDirection.Bottom || connectedDirection2 == ConnectedDirection.Bottom),
					(connectedDirection1 == ConnectedDirection.Left || connectedDirection2 == ConnectedDirection.Left),
					(connectedDirection1 == ConnectedDirection.Right || connectedDirection2 == ConnectedDirection.Right));

				cell.gridCell.SetColor(lineColor);
			}

			if (drawPlacedImages)
			{
				cell.gridCell.SetPlaced(lineColor);
			}
		}

		/// <summary>
		/// Gets the connection direction from the give lineCell to the line cell at the given adjacentIndex
		/// </summary>
		private ConnectedDirection GetConnectionDirection(PlacedLine placedLine, LineCell lineCell, int adjacentIndex)
		{
			ConnectedDirection connectedDirection = ConnectedDirection.None;

			if (adjacentIndex <= 0)
			{
				connectedDirection = GetConnectionDirection(lineCell.cellPos, placedLine.EndCell1.cellPos);
			}
			else if (adjacentIndex >= placedLine.lineSegments.Count - 1)
			{
				if (placedLine.EndCell2.isEndConnected)
				{
					connectedDirection = GetConnectionDirection(lineCell.cellPos, placedLine.EndCell2.cellPos);
				}
			}
			else
			{
				LineCell adjacentLineCell = placedLine.lineSegments[adjacentIndex];

				if (!adjacentLineCell.isCut)
				{
					connectedDirection = GetConnectionDirection(lineCell.cellPos, adjacentLineCell.cellPos);
				}
			}

			return connectedDirection;
		}

		/// <summary>
		/// Gets the direction of connection from cellPos1 to cellPos2, return None if they arn't connected
		/// </summary>
		private ConnectedDirection GetConnectionDirection(CellPos cellPos1, CellPos cellPos2)
		{
			int rowDiff = cellPos1.row - cellPos2.row;
			int colDiff = cellPos1.col - cellPos2.col;

			if (rowDiff == 1 && colDiff == 0)
			{
				return ConnectedDirection.Top;
			}

			if (rowDiff == -1 && colDiff == 0)
			{
				return ConnectedDirection.Bottom;
			}

			if (rowDiff == 0 && colDiff == -1)
			{
				return ConnectedDirection.Right;
			}

			if (rowDiff == 0 && colDiff == 1)
			{
				return ConnectedDirection.Left;
			}

			return ConnectedDirection.None;
		}

		/// <summary>
		/// Gets the color of the line.
		/// </summary>
		private Color GetLineColor(int lineIndex)
		{
			return lineColors[lineIndex % lineColors.Count];
		}

		/// <summary>
		/// Sets the given GridCell blank so there is no lines on it
		/// </summary>
		private void ClearLineSegment(Cell cell)
		{
			cell.lineCell = null;
			cell.gridCell.ClearLineSegment();
		}

		/// <summary>
		/// Sets all GridCells to blank
		/// </summary>
		private void ResetGridCells()
		{
			for (int i = 0; i < grid.Count; i++)
			{
				for (int j = 0; j < grid[i].Count; j++)
				{
					ClearLineSegment(grid[i][j]);
				}
			}
		}

		/// <summary>
		/// Clears all placed line segments.
		/// </summary>
		private void ClearAllLineSegments()
		{
			for (int i = 0; i < placedLines.Count; i++)
			{
				placedLines[i].Clear();
			}
		}

		/// <summary>
		/// Sets all PlacedLine lineSegments to be positions in the given positions
		/// </summary>
		private void CreateLineCells(List<List<CellPos>> lineSegmentPositions)
		{
			for (int i = 0; i < placedLines.Count; i++)
			{
				PlacedLine		placedLine			= placedLines[i];
				List<CellPos>	segmentPositions	= lineSegmentPositions[i];

				// Clear all segments
				placedLine.Clear();

				// Make sure the end points sync up
				if (!placedLine.lineSegments[0].cellPos.Equals(segmentPositions[0]))
				{
					LineCell lineCell = placedLine.lineSegments[0];

					placedLine.lineSegments[0] = placedLine.lineSegments[1];
					placedLine.lineSegments[1] = lineCell;
				}

				// Now re-build the line
				for (int j = 1; j < segmentPositions.Count - 1; j++)
				{
					CellPos cellPos = segmentPositions[j];

					placedLine.InsertLineSegment(j, new LineCell(cellPos.row, cellPos.col, i));
				}

				// Set the end point connection flags
				placedLine.EndCell1.isEndConnected = placedLine.lineSegments.Count > 2;
				placedLine.EndCell2.isEndConnected = placedLine.lineSegments.Count > 2 && AreCellsAdjacent(placedLine.EndCell2.cellPos, placedLine.lineSegments[placedLine.lineSegments.Count - 2].cellPos);
			}
		}

		/// <summary>
		/// Sets the numMoves and updates the Text UI
		/// </summary>
		private void SetNumMoves(int amount)
		{
			currentLevelSaveData.numMoves = amount;

			moveAmountText.text = currentLevelSaveData.numMoves.ToString();
		}

		/// <summary>
		/// Updates the amount of placed lines
		/// </summary>
		private void UpdateLinesText()
		{
			int connectedLines = 0;

			for (int i = 0; i < placedLines.Count; i++)
			{
				PlacedLine placedLine = placedLines[i];

				if (placedLine.EndCell1.isEndConnected && placedLine.EndCell2.isEndConnected)
				{
					connectedLines++;
				}
			}

			lineAmountText.text = connectedLines + "/" + placedLines.Count;
		}

		// Updates the fill percentate
		private void UpdateFillText()
		{
			int placedCells = 0;

			for (int i = 0; i < placedLines.Count; i++)
			{
				placedCells += placedLines[i].lineSegments.Count - 2;
			}

			float percentage = 100f * ((float)placedCells / (float)totalBlankCells);

			if (percentage > 99f)
			{
				percentage = Mathf.Floor(percentage);
			}
			else
			{
				percentage = Mathf.Ceil(percentage);
			}

			fillAmountText.text = ((int)percentage).ToString() + "%";
		}

		private void PrintLines(List<List<CellPos>> cellPositions)
		{
			if (cellPositions == null) return;
			string str = "Cell positions";

			for (int i = 0; i < cellPositions.Count; i++)
			{
				str += string.Format("\n{0} : {1}", i, PrintLine(cellPositions[i]));
			}

			Debug.Log(str);
		}

		private string PrintLine(List<CellPos> cellPositions)
		{
			string str = "";

			for (int i = 0; i < cellPositions.Count; i++)
			{
				CellPos cellPos = cellPositions[i];

				if (i != 0) str += ", ";

				str += cellPos.ToString();
			}

			return str;
		}


		private void PrintPlacedLines()
		{
			string str = "placed Lines";

			for (int i = 0; i < placedLines.Count; i++)
			{
				str += string.Format("\n{0} : {1}", i, PrintPlacedLine(placedLines[i]));
			}

			Debug.Log(str);
		}

		private string PrintPlacedLine(PlacedLine placedLine)
		{
			string str = "";

			for (int i = 0; i < placedLine.lineSegments.Count; i++)
			{
				CellPos cellPos = placedLine.lineSegments[i].cellPos;

				if (i != 0) str += ", ";

				str += cellPos.ToString();
			}

			return str;
		}

		#endregion

		#endregion
	}
}
