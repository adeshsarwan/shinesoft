using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace BizzyBeeGames.DotConnect
{
	public class LevelCreatorWorker : Worker
	{
		#region Classes

		private class AlgoData
		{
			public int rowCount;
			public int colCount;

			public List<GridCell>	grid;
			public List<GridCell>	activeGridCells;
			public int				nextIndex;
			public bool				allPaths;

			public List<Dictionary<int, CellType>>	cellTypeUndoList	= new List<Dictionary<int, CellType>>();
			public List<Dictionary<int, int>>		lineNumberUndoList	= new List<Dictionary<int, int>>();

			/// <summary>
			/// Begins a new undo set
			/// </summary>
			public void BeginUndo()
			{
				UndoCellTypeBegin();
				UndoLineNumberBegin();
			}

			/// <summary>
			/// Ends the current undo set
			/// </summary>
			public void EndUndo()
			{
				UndoCellTypeEnd();
				UndoLineNumberEnd();
			}

			/// <summary>
			/// Begins a new undo set for cell types
			/// </summary>
			public void UndoCellTypeBegin()
			{
				cellTypeUndoList.Add(new Dictionary<int, CellType>());
			}

			/// <summary>
			/// Ends the current undo set cell types
			/// </summary>
			public void UndoCellTypeEnd()
			{
				Dictionary<int, CellType> undos = cellTypeUndoList[cellTypeUndoList.Count - 1];

				cellTypeUndoList.RemoveAt(cellTypeUndoList.Count - 1);

				foreach (KeyValuePair<int, CellType> pair in undos)
				{
					grid[pair.Key].cellType = pair.Value;
				}
			}

			/// <summary>
			/// Begins a new undo set for line numbers
			/// </summary>
			public void UndoLineNumberBegin()
			{
				lineNumberUndoList.Add(new Dictionary<int, int>());
			}

			/// <summary>
			/// Ends the current undo set line numbers
			/// </summary>
			public void UndoLineNumberEnd()
			{
				Dictionary<int, int> undos = lineNumberUndoList[lineNumberUndoList.Count - 1];

				lineNumberUndoList.RemoveAt(lineNumberUndoList.Count - 1);

				foreach (KeyValuePair<int, int> pair in undos)
				{
					grid[pair.Key].lineNumber = pair.Value;
				}
			}

			/// <summary>
			/// Gets the cell type for the GridCell at row/col, logs an undo step
			/// </summary>
			public void SetCellType(GridCell gridCell, CellType cellType)
			{
				int index = GetIndex(gridCell.row, gridCell.col);

				Dictionary<int, CellType> currentUndoSet = cellTypeUndoList[cellTypeUndoList.Count - 1];

				if (!currentUndoSet.ContainsKey(index))
				{
					currentUndoSet.Add(index, grid[index].cellType);
				}

				grid[index].cellType = cellType;
			}

			/// <summary>
			/// Gets the line number for the GridCell at row/col, logs an undo step
			/// </summary>
			public void SetLineNumber(GridCell gridCell, int lineNumber)
			{
				int index = GetIndex(gridCell.row, gridCell.col);

				Dictionary<int, int> currentUndoSet = lineNumberUndoList[lineNumberUndoList.Count - 1];

				if (!currentUndoSet.ContainsKey(index))
				{
					currentUndoSet.Add(index, grid[index].lineNumber);
				}

				grid[index].lineNumber = lineNumber;
			}

			/// <summary>
			/// Gets the index into grid using the row/col
			/// </summary>
			public int GetIndex(int row, int col)
			{
				return row * colCount + col;
			}
		}

		private class GridCell
		{
			public int		row;
			public int		col;
			public CellType	cellType;
			public int		lineNumber;
			public int		lineLengthMarker;
			public int		regionMarker;
			public int		adjacentMarker;
			public int		getLineMarker;

			public bool IsNotAssigned 	{ get { return cellType == CellType.NotAssigned; } }
			public bool IsBlock 		{ get { return cellType == CellType.Block; } }
			public bool IsDot			{ get { return cellType == CellType.Dot; } }
			public bool IsLineSegment	{ get { return cellType == CellType.LineSegment; } }
			public bool IsUnConnected	{ get { return cellType == CellType.UnConnectedLineSegment; } }

			public GridCell(int row, int col)
			{
				this.row = row;
				this.col = col;
			}

			public override string ToString()
			{
				return string.Format("[{0},{1}] {2}", row, col, cellType);
			}
		}

		private class Move
		{
			public MoveType moveType;
			public GridCell fromCell;
			public GridCell toCell;
		}

		#endregion

		#region Enums

		public enum ErrorType
		{
			None,
			InvalidGridCells,
			InvalidGridLines,
			Exception
		}

		private enum CellType
		{
			NotAssigned,
			Block,
			Dot,
			LineSegment,
			UnConnectedLineSegment
		}

		private enum MoveType
		{
			Push,	// One dot moves into the space of another dot and pushes the other dot along it's line
			Join,	// One dot joins with another dot creating one line
			Split	// One dot splits another line into two lines by moving removing the other lines line segment and moving its dot there
		}

		#endregion

		#region Variables

		private System.Random			random;
		private int						currentLineLengthMarker;
		private int						currentRegionMarker;
		private int						currentAdjacentMarker;
		private int						currentGetLineMarker;
		private int						currentNumLines;
		private int						uniqueLineNumber;
		private List<List<GridCell>>	grid;
		private List<GridCell>			dotCells;

		#endregion

		#region Properties

		// In properties
		public int				NumMoves		{ get; set; }
		public int				MinLines		{ get; set; }
		public int				MaxLines		{ get; set; }
		public List<List<bool>> BlockPositions	{ get; set; }
		public int				RandSeed		{ get; set; }
		public bool				EnableLogging	{ get; set; }
		public string			LogFilePath		{ get; set; }

		// Out properties
		public ErrorType		Error			{ get; set; }

		#endregion

		#region Public Methods

		/// <summary>
		/// Gets a list of all the lines segements on the grid
		/// </summary>
		public List<List<int>> GetLineCoordinates()
		{
			List<List<int>>	coordinates	= new List<List<int>>();
			HashSet<int>	linesAdded	= new HashSet<int>();

			for (int r = 0; r < grid.Count; r++)
			{
				for (int j = 0; j < grid[r].Count; j++)
				{
					GridCell gridCell = grid[r][j];

					if (gridCell.IsDot && !linesAdded.Contains(gridCell.lineNumber))
					{
						List<GridCell>	lineGridCells	= GetAllGridCellsInLine(gridCell, true);
						List<int>		lineCoordinates	= new List<int>();

						for (int k = 0; k < lineGridCells.Count; k++)
						{
							lineCoordinates.Add(grid.Count - 1 - lineGridCells[k].row);
							lineCoordinates.Add(lineGridCells[k].col);
						}

						coordinates.Add(lineCoordinates);
						linesAdded.Add(gridCell.lineNumber);
					}
				}
			}

			return coordinates;
		}

		#endregion

		#region Protected Methods

		protected override void Begin()
		{
			random = new System.Random(RandSeed);

			if (EnableLogging)
			{
				// Create the log file and make sure its blank
				System.IO.File.WriteAllText(LogFilePath, "");

				Log("Seed: " + RandSeed);
			}
		}

		protected override void DoWork()
		{
			try
			{
				// First init the grid then try placing the initial lines in the simple case by only moving the lines right/down on the grid
				// In most cases this succeeds in creating a valid initial grid and is faster than trying all possible directions
				InitGrid();
				PlaceInitialLines(false);

				// If the worker is stopping don't run the rest of the code
				if (Stopping) return;

				// Check if the grid is valid
				if (IsGridValid(false) != 0)
				{
					Log("Simple case failed, trying all possible lines");
					InitGrid();
					PlaceInitialLines(true);
				}

				// If the worker is stopping don't run the rest of the code
				if (Stopping) return;

				// Grid should be valid now
				int result = IsGridValid(true);

				if (result != 0)
				{
					Error = (result == 1) ? ErrorType.InvalidGridCells : ErrorType.InvalidGridLines;
				}
				else
				{
					Log("Initial lines placed, starting to make random moves");

					LogGrid("Initial");

					// Get all the Cells with dots on them
					dotCells = new List<GridCell>();

					for (int r = 0; r < grid.Count; r++)
					{
						for (int c = 0; c < grid[r].Count; c++)
						{
							GridCell gridCell = grid[r][c];

							if (gridCell.IsDot)
							{
								dotCells.Add(gridCell);
							}
						}
					}

					currentNumLines = dotCells.Count / 2;

					int moveCount = 0;

					// Make random moves until we reach the number of interations or there are no more valid moves to make
					while (!Stopping && moveCount++ < NumMoves && MakeMove()) { }

					LogGrid("Final");

					// Do a final sanity check to make sure the random moves didn't some how mess up the grid
					result = IsGridValid(true);

					if (result != 0)
					{
						Error = (result == 1) ? ErrorType.InvalidGridCells : ErrorType.InvalidGridLines;
					}
					else
					{
						Error = ErrorType.None;
					}
				}
			}
			catch (System.Exception ex)
			{
				Log("An exception occured:");
				Log(ex.Message);
				Log(ex.StackTrace);

				Error = ErrorType.Exception;

				Debug.LogError(ex.Message + "\n" + ex.StackTrace);
			}

			Stop();
		}

		#endregion

		#region Private Methods

		private void InitGrid()
		{
			grid = new List<List<GridCell>>();

			for (int i = 0; i < BlockPositions.Count; i++)
			{
				grid.Add(new List<GridCell>());

				for (int j = 0; j < BlockPositions[i].Count; j++)
				{
					GridCell gridCell = new GridCell(i, j);

					if (BlockPositions[i][j])
					{
						gridCell.cellType = CellType.Block;
					}

					grid[i].Add(gridCell);
				}
			}
		}

		#region Initial Board Creation

		private bool PlaceInitialLines(bool allPaths)
		{
			uniqueLineNumber = 1;

			AlgoData algoData = new AlgoData();

			algoData.rowCount			= grid.Count;
			algoData.colCount			= grid[0].Count;
			algoData.grid				= new List<GridCell>();
			algoData.activeGridCells	= new List<GridCell>();
			algoData.nextIndex			= 0;
			algoData.allPaths			= allPaths;

			// First copy the GridCells to the AlgoDatas grid cell list
			for (int r = 0; r < grid.Count; r++)
			{
				for (int c = 0; c < grid[r].Count; c++)
				{
					GridCell gridCell = grid[r][c];

					algoData.grid.Add(gridCell);
				}
			}

			// Next get all active grid cells which are cells that are not blocks
			for (int r = grid.Count - 1; r >= 0; r--)
			{
				for (int c = 0; c < grid[r].Count; c++)
				{
					GridCell gridCell = grid[r][c];

					if (!gridCell.IsBlock)
					{
						algoData.activeGridCells.Add(gridCell);
					}
				}
			}

			// Start the algorithum
			return AlgoStep1(algoData);
		}

		/// <summary>
		/// Step1: Place dots on all dead ends
		/// </summary>
		private bool AlgoStep1(AlgoData algoData)
		{
			if (Stopping) return false;

			algoData.BeginUndo();

			bool result = PlaceDotsOnDeadEnds(algoData);

			LogGrid("AlgoStep1");

			if (result && RegionSizeCheck(algoData) && AlgoStep2(algoData))
			{
				return true;
			}

			algoData.EndUndo();

			return false;
		}

		/// <summary>
		/// Step 2: Get the next top/left GridCell to try and place a dot on it
		/// </summary>
		private bool AlgoStep2(AlgoData algoData)
		{
			if (Stopping) return false;

			// Check if there are no more cells to try and place dots on
			if (algoData.nextIndex >= algoData.activeGridCells.Count)
			{
				// Only check for un-assigned / un-connected cells if we are doing all possible lines
				if (algoData.allPaths)
				{
					// Check if all the active cells have been assigned to dot or line segment
					for (int i = 0; i < algoData.activeGridCells.Count; i++)
					{
						GridCell gridCell = algoData.activeGridCells[i];

						if (gridCell.IsNotAssigned || gridCell.IsUnConnected)
						{
							return false;
						}
					}
				}

				// We are finished
				return true;
			}

			// Get the next cell to place a dot on
			GridCell nextGridCell = algoData.activeGridCells[algoData.nextIndex];

			algoData.nextIndex++;

			if (AlgoStep3(algoData, nextGridCell))
			{
				return true;
			}

			algoData.nextIndex--;

			return false;
		}

		/// <summary>
		/// Step 3: If the grid cell is not assigned place a dot on it and call AlgoStep4 which will begin trying to extend a line from the dot.
		/// 		If the grid cell is un-connected try and extend it and create a line from it.
		/// </summary>
		private bool AlgoStep3(AlgoData algoData, GridCell gridCell)
		{
			if (Stopping) return false;

			if (gridCell.IsUnConnected)
			{
				algoData.BeginUndo();

				// Try and extend the un-connected line
				if (AlgoStep4a(algoData, gridCell, gridCell.lineNumber, GetLineLength(gridCell), true))
				{
					return true;
				}

				algoData.EndUndo();
			}
			else if (gridCell.IsNotAssigned)
			{
				algoData.BeginUndo();

				int lineNumber = uniqueLineNumber++;

				// First create a dot on gridCell
				algoData.SetCellType(gridCell, CellType.Dot);
				algoData.SetLineNumber(gridCell, lineNumber);

				LogGrid(string.Format("PSD r:{0}, c:{1}", gridCell.row, gridCell.col));

				// Now try and extend the line
				if (AlgoStep4a(algoData, gridCell, lineNumber, 1, true))
				{
					return true;
				}

				algoData.EndUndo();
			}

			return AlgoStep2(algoData);
		}

		/// <summary>
		/// Step4: Try and extend the line one more space, if there are no more valid adjacent cells to extend to try and place an ending dot on gridCell
		/// </summary>
		private bool AlgoStep4a(AlgoData algoData, GridCell gridCell, int lineNumber, int lineLength, bool first = false)
		{
			if (Stopping) return false;

			List<int[]>		adjacentPositions	= null;
			List<GridCell>	adjacentEmptyCells	= new List<GridCell>();

			// Get the adjacent cell row/cols to try and extend the line to
			if (algoData.allPaths)
			{
				adjacentPositions = GetAdjacentCellPositions(gridCell);
			}
			else
			{
				adjacentPositions = GetAdjacentCellPositionsForSimpleCase(gridCell);
			}

			// Get the GridCells at the adjacent positions it the cell is a valid cell we can extend the line to
			for (int i = 0; i < adjacentPositions.Count; i++)
			{
				int[] rowCol = adjacentPositions[i];

				GridCell adjacentCell;

				if (TryGetGridCell(rowCol[0], rowCol[1], out adjacentCell) &&													// The cell at row/col is on the grid
				    ((adjacentCell.IsNotAssigned && !IsCellAdjacentToLineNumber(adjacentCell, gridCell, lineNumber, false)) ||	// The cell is not assigned and is not adjacent a line segment belonging to the line we are trying to extend
				     (adjacentCell.IsUnConnected && !IsCellAdjacentToLineNumber(adjacentCell, gridCell, lineNumber, true))))	// The cell is un-connected and the line belonging to the un-connected cell doesn't have any cells adjacent to the line we are extending
				{
					// This is a valid cell we can extend the line to
					adjacentEmptyCells.Add(adjacentCell);
				}
			}

			// Check if there are any valid cells we can extend the line to
			if (adjacentEmptyCells.Count > 0)
			{
				// Do a region check now
				if (!first && !RegionSizeCheck(algoData))
				{
					// Failed region check, the last placed line segment created a grid which cannot contain a region which is to small to fill with valid lines
					return false;
				}

				algoData.BeginUndo();

				// If the cell we are extending from is un-connected make it a line segment now
				if (gridCell.IsUnConnected)
				{
					algoData.SetCellType(gridCell, CellType.LineSegment);
				}

				// Try to extend the line to all valid adjacent cells
				for (int i = 0; i < adjacentEmptyCells.Count; i++)
				{
					if (Stopping) return false;

					if (AlgoStep4b(algoData, adjacentEmptyCells[i], lineNumber, lineLength))
					{
						return true;
					}
				}

				algoData.EndUndo();
			}

			if (Stopping) return false;

			// Could not extend the line any more, try and create a dot
			if (lineLength >= 3)
			{
				algoData.BeginUndo();

				// Set the cell as a dot
				algoData.SetCellType(gridCell, CellType.Dot);
				algoData.SetLineNumber(gridCell, lineNumber);

				LogGrid(string.Format("PED r:{0}, c:{1}", gridCell.row, gridCell.col));

				// Now that we placed a new line restart the algorithm at step 1
				if (AlgoStep1(algoData))
				{
					return true;
				}

				algoData.EndUndo();
			}

			return false;
		}

		/// <summary>
		/// Extends the line to the given GridCell
		/// </summary>
		private bool AlgoStep4b(AlgoData algoData, GridCell gridCell, int lineNumber, int lineLength)
		{
			if (Stopping) return false;

			algoData.BeginUndo();

			if (gridCell.IsNotAssigned)
			{
				// If the grid cell is un-assigned set the cell to an un-connected line segment
				algoData.SetCellType(gridCell, CellType.UnConnectedLineSegment);
				algoData.SetLineNumber(gridCell, lineNumber);

				// Place dots on any dead ends that may have been created
				bool placeDeadEndsResult = PlaceDotsOnDeadEnds(algoData, gridCell);

				LogGrid(string.Format("PLS r:{0}, c:{1}", gridCell.row, gridCell.col));

				// Continue trying to extend the line
				if (placeDeadEndsResult && AlgoStep4a(algoData, gridCell, lineNumber, lineLength + 1))
				{
					return true;
				}
			}
			else if (gridCell.IsUnConnected)
			{
				// Connect the lines by setting all of the un-connect line segments/dot to the current line number
				algoData.SetCellType(gridCell, CellType.LineSegment);

				SetAllCellsToLineNumber(algoData, gridCell, lineNumber);

				LogGrid(string.Format("CLS r:{0}, c:{1}", gridCell.row, gridCell.col));

				// Now that we placed a new line restart the algorithm at step 1
				if (AlgoStep1(algoData))
				{
					return true;
				}
			}

			algoData.EndUndo();

			return false;
		}

		/// <summary>
		/// Adds a dot on all GridCells that are dead ends
		/// </summary>
		private bool PlaceDotsOnDeadEnds(AlgoData algoData, GridCell ignoreUnconnectedCell = null)
		{
			for (int i = 0; i < algoData.activeGridCells.Count; i++)
			{
				if (Stopping) return false;

				GridCell gridCell = algoData.activeGridCells[i];

				GridCell emptyAdjacentCell;

				if (gridCell.IsNotAssigned && IsDeadEnd(gridCell, out emptyAdjacentCell) && (emptyAdjacentCell == null || emptyAdjacentCell != ignoreUnconnectedCell))
				{
					if (emptyAdjacentCell == null)
					{
						return false;
					}

					algoData.SetCellType(gridCell, CellType.Dot);
					algoData.SetLineNumber(gridCell, uniqueLineNumber++);

					if (!ExtendDeadEnd(algoData, gridCell, emptyAdjacentCell, ignoreUnconnectedCell, gridCell.lineNumber, 1))
					{
						return false;
					}
				}
				else if (gridCell.IsUnConnected && gridCell != ignoreUnconnectedCell && IsDeadEnd(gridCell, out emptyAdjacentCell) && GetLineLength(gridCell) == 2 && (emptyAdjacentCell == null || emptyAdjacentCell != ignoreUnconnectedCell))
				{
					if (emptyAdjacentCell == null)
					{
						return false;
					}

					algoData.SetCellType(gridCell, CellType.LineSegment);

					if (!ExtendDeadEnd(algoData, gridCell, emptyAdjacentCell, ignoreUnconnectedCell, gridCell.lineNumber, 2))
					{
						return false;
					}
				}
			}

			return true;
		}

		/// <summary>
		/// Extends the dead end.
		/// </summary>
		private bool ExtendDeadEnd(AlgoData algoData, GridCell lastCell, GridCell nextCell, GridCell ignoreCell, int lineNumber, int lineLength)
		{
			if (Stopping)
			{
				return false;
			}

			// If the next cell is un-connected then we reached another dead end line so join with it
			if (nextCell.IsUnConnected)
			{
				if (IsCellAdjacentToLineNumber(nextCell, lastCell, lineNumber, true))
				{
					return false;
				}

				algoData.SetCellType(nextCell, CellType.LineSegment);

				SetAllCellsToLineNumber(algoData, nextCell, lineNumber);

				return true;
			}
			else
			{
				algoData.SetLineNumber(nextCell, lineNumber);

				GridCell emptyAdjacentCell;

				// Check if the next cell is also a dead end
				if (IsDeadEnd(nextCell, out emptyAdjacentCell))
				{
					// If emptyAdjacentCell is null then there is no were else to go
					if (emptyAdjacentCell == null)
					{
						// If the current extended lin length is less than 2 then we cannot form a valid line
						if (lineLength < 2)
						{
							return false;
						}
						else
						{
							// Place a dot on nextEmptyCell to complete the line
							algoData.SetCellType(nextCell, CellType.Dot);

							// We formed a valid line
							return true;
						}
					}
					else
					{
						if (lineLength >= 2 || emptyAdjacentCell == ignoreCell)
						{
							algoData.SetCellType(nextCell, CellType.UnConnectedLineSegment);

							return true;
						}

						// Set it as a line segement
						algoData.SetCellType(nextCell, CellType.LineSegment);

						// Continue to extend it
						return ExtendDeadEnd(algoData, nextCell, emptyAdjacentCell, ignoreCell, lineNumber, lineLength + 1);
					}
				}
				else
				{
					algoData.SetCellType(nextCell, CellType.UnConnectedLineSegment);

					return true;
				}
			}
		}

		/// <summary>
		/// Joins the two seperate lines.
		/// </summary>
		private void SetAllCellsToLineNumber(AlgoData algoData, GridCell gridCell, int lineNumber)
		{
			List<GridCell> allToCells = GetAllGridCellsInLine(gridCell);

			// Set the line numbers in toCell line to fromCells line number
			for (int i = 0; i < allToCells.Count; i++)
			{
				algoData.SetLineNumber(allToCells[i], lineNumber);
			}
		}

		/// <summary>
		/// Checks if the given GridCell is a dead end meaning there is only one adjacent cell which is empty (And thus only one direction a line segment can go)
		/// </summary>
		private bool IsDeadEnd(GridCell gridCell, out GridCell emptyAdjacentCell)
		{
			emptyAdjacentCell = null;

			List<int[]> adjacentPositions = GetAdjacentCellPositions(gridCell);

			int emptyCells = 0;

			for (int i = 0; i < adjacentPositions.Count; i++)
			{
				GridCell adjacentCell;

				if (TryGetGridCell(adjacentPositions[i][0], adjacentPositions[i][1], out adjacentCell) && (adjacentCell.IsNotAssigned || adjacentCell.IsUnConnected))
				{
					emptyCells++;
					emptyAdjacentCell = adjacentCell;
				}
			}

			return emptyCells <= 1;
		}

		/// <summary>
		/// Returns false if there is any closed region on the grid that is less than 2 blocks
		/// </summary>
		private bool RegionSizeCheck(AlgoData algoData)
		{
			currentRegionMarker++;

			for (int i = 0; i < algoData.activeGridCells.Count; i++)
			{
				GridCell gridCell = algoData.activeGridCells[i];

				if ((gridCell.IsNotAssigned || gridCell.IsUnConnected) && gridCell.regionMarker != currentRegionMarker)
				{
					int count = CountRegionCells(gridCell.row, gridCell.col);

					// Regions which are 4 or 5 is size can only be filled it the region is straight
					if (count <= 2 || (count <= 5 && !IsRegionStraight(gridCell)))
					{
						return false;
					}
				}
			}

			return true;
		}

		/// <summary>
		/// Counds all the not assigned cells in a region
		/// </summary>
		private int CountRegionCells(int row, int col)
		{
			GridCell gridCell;

			if (!TryGetGridCell(row, col, out gridCell))
			{
				return 0;
			}

			if (gridCell.regionMarker == currentRegionMarker)
			{
				return 0;
			}

			gridCell.regionMarker = currentRegionMarker;

			if (gridCell.IsBlock || gridCell.IsDot || gridCell.IsLineSegment)
			{
				return 0;
			}
			
			int count = 1;

			if (gridCell.IsUnConnected)
			{
				count = GetLineLength(gridCell);
			}

			count += CountRegionCells(row + 1, col);
			count += CountRegionCells(row - 1, col);
			count += CountRegionCells(row, col + 1);
			count += CountRegionCells(row, col - 1);

			return count;
		}

		/// <summary>
		/// Checks if a region is straight (Only works properly for regions which have 5 or less cells
		/// </summary>
		private bool IsRegionStraight(GridCell startCell)
		{
			List<int> lineNumbers = new List<int>();

			if (startCell.IsUnConnected)
			{
				lineNumbers.Add(startCell.lineNumber);
			}

			List<GridCell> adjacentCells = GetAdjacentCells(startCell);

			for (int i = 0; i < adjacentCells.Count; i++)
			{
				GridCell gridCell = adjacentCells[i];

				if (gridCell.IsBlock || ((gridCell.IsDot || gridCell.IsLineSegment) && !lineNumbers.Contains(gridCell.lineNumber)))
				{
					adjacentCells.RemoveAt(i);
					i--;
				}
			}

			if (adjacentCells.Count == 0)
			{
				return true;
			}

			if (adjacentCells.Count == 1)
			{
				return IsRegionStraight(startCell, adjacentCells[0], startCell, lineNumbers);
			}

			if (adjacentCells.Count == 2)
			{
				return IsRegionStraight(startCell, adjacentCells[0], startCell, lineNumbers) && IsRegionStraight(startCell, adjacentCells[1], startCell, lineNumbers);
			}

			return false;
		}

		private bool IsRegionStraight(GridCell fromCell, GridCell toCell, GridCell startCell, List<int> lineNumbers)
		{
			if (toCell.IsUnConnected)
			{
				lineNumbers.Add(toCell.lineNumber);
			}

			List<GridCell> adjacentCells = GetAdjacentCells(toCell);

			for (int i = 0; i < adjacentCells.Count; i++)
			{
				GridCell gridCell = adjacentCells[i];

				if (gridCell == fromCell || gridCell.IsBlock || ((gridCell.IsDot || gridCell.IsLineSegment) && !lineNumbers.Contains(gridCell.lineNumber)))
				{
					adjacentCells.RemoveAt(i);
					i--;
				}
			}

			if (adjacentCells.Count == 0)
			{
				if (toCell.IsUnConnected)
				{
					lineNumbers.RemoveAt(lineNumbers.Count - 1);
				}

				return true;
			}

			if (adjacentCells.Count > 1)
			{
				return false;
			}

			if (adjacentCells[0] == startCell)
			{
				return false;
			}

			bool result = IsRegionStraight(toCell, adjacentCells[0], startCell, lineNumbers);

			if (toCell.IsUnConnected)
			{
				lineNumbers.RemoveAt(lineNumbers.Count - 1);
			}

			return result;
		}

		#endregion //Initial Board Creation

		private bool MakeMove()
		{
			List<List<Move>> allPossibleMoves = new List<List<Move>>();

			for (int i = 0; i < dotCells.Count; i++)
			{
				GridCell dotCell = dotCells[i];

				List<Move> possibleMoves = GetPossibleMoves(dotCell);

				if (possibleMoves.Count > 0)
				{
					allPossibleMoves.Add(possibleMoves);
				}
			}

			if (allPossibleMoves.Count == 0)
			{
				return false;
			}

			// Pick a random list to choose from
			List<Move>	moves	= allPossibleMoves[random.Next(0, allPossibleMoves.Count)];
			Move		move	= moves[random.Next(0, moves.Count)];

			DoMove(move);

			return true;
		}

		private void DoMove(Move move)
		{
			switch (move.moveType)
			{
				case MoveType.Push:
					DoPushMove(move.fromCell, move.toCell);
					break;
				case MoveType.Join:
					DoJoinMove(move.fromCell, move.toCell);
					break;
				case MoveType.Split:
					DoSplitMove(move.fromCell, move.toCell);
					break;
			}

			LogGrid(string.Format("{0} : {1}, {2}", move.moveType, move.fromCell, move.toCell));
		}

		private void DoPushMove(GridCell fromCell, GridCell toCell)
		{
			GridCell nextCell = GetAdjacentLineSegments(toCell)[0];	// Since this is a valid push the toCell is a dot and will only have one adjacent cell

			// Move the dot at fromCell to where the dot at toCell is and move the dot at toCell to the next line segment in its line
			nextCell.cellType	= CellType.Dot;
			fromCell.cellType	= CellType.LineSegment;
			toCell.cellType		= CellType.Dot;
			toCell.lineNumber	= fromCell.lineNumber;

			// Update the dotCells list
			dotCells.Remove(fromCell);
			dotCells.Add(nextCell);
		}

		private void DoJoinMove(GridCell fromCell, GridCell toCell)
		{
			List<GridCell> allToCells	= GetAllGridCellsInLine(toCell);
			List<GridCell> allFromCells	= GetAllGridCellsInLine(fromCell);

			if (allToCells.Count == 1 && allFromCells.Count == 1)
			{
				toCell.lineNumber = fromCell.lineNumber;
			}
			else if (allToCells.Count == 1)
			{
				toCell.lineNumber	= fromCell.lineNumber;
				fromCell.cellType	= CellType.LineSegment;
				dotCells.Remove(fromCell);
			}
			else if (allFromCells.Count == 1)
			{
				fromCell.lineNumber	= toCell.lineNumber;
				toCell.cellType		= CellType.LineSegment;
				dotCells.Remove(toCell);
			}
			else
			{
				// Set the line numbers in toCell line to fromCells line number
				for (int i = 0; i < allToCells.Count; i++)
				{
					allToCells[i].lineNumber = fromCell.lineNumber;
				}

				// Set the types to line segments to complete the line
				fromCell.cellType	= CellType.LineSegment;
				toCell.cellType		= CellType.LineSegment;

				// Update the dotCells list
				dotCells.Remove(fromCell);
				dotCells.Remove(toCell);
			}

			currentNumLines--;
		}

		private void DoSplitMove(GridCell fromCell, GridCell toCell)
		{
			List<GridCell> adjacentLineSegments = GetAdjacentLineSegments(toCell);

			fromCell.cellType	= CellType.LineSegment;
			toCell.cellType		= CellType.Dot;
			toCell.lineNumber	= fromCell.lineNumber;

			adjacentLineSegments[0].cellType = CellType.Dot;
			adjacentLineSegments[1].cellType = CellType.Dot;

			// Set one of the new lines to a new line number
			List<GridCell>	lineGridCells	= GetAllGridCellsInLine(adjacentLineSegments[0]);
			int				newLineNumber	= uniqueLineNumber++;

			for (int i = 0; i < lineGridCells.Count; i++)
			{
				lineGridCells[i].lineNumber = newLineNumber;
			}

			// Update the dotCells list
			dotCells.Remove(fromCell);
			dotCells.Add(toCell);
			dotCells.Add(adjacentLineSegments[0]);
			dotCells.Add(adjacentLineSegments[1]);

			currentNumLines++;
		}

		/// <summary>
		/// Gets the next GridCell in the line from the fromcCell
		/// </summary>
		private List<GridCell> GetAdjacentLineSegments(GridCell fromCell)
		{
			List<GridCell> adjacentLineSegments	= new List<GridCell>();
			List<GridCell> adjacentCells		= GetAdjacentCells(fromCell);

			for (int i = 0; i < adjacentCells.Count; i++)
			{
				GridCell adjacentCell = adjacentCells[i];

				if (adjacentCell.lineNumber == fromCell.lineNumber)
				{
					adjacentLineSegments.Add(adjacentCell);
				}
			}

			return adjacentLineSegments;
		}

		/// <summary>
		/// Gets all the GridCells in the line from the fromCell
		/// </summary>
		private List<GridCell> GetAllGridCellsInLine(GridCell fromCell, bool newMarker = true)
		{
			if (newMarker)
			{
				currentGetLineMarker++;
			}

			List<GridCell> lineGridCells = new List<GridCell>();
			List<GridCell> adjacentCells = GetAdjacentCells(fromCell);

			fromCell.getLineMarker = currentGetLineMarker;

			lineGridCells.Add(fromCell);

			for (int i = 0; i < adjacentCells.Count; i++)
			{
				GridCell adjacentCell = adjacentCells[i];

				if (adjacentCell.getLineMarker != currentGetLineMarker && adjacentCell.lineNumber == fromCell.lineNumber)
				{
					lineGridCells.AddRange(GetAllGridCellsInLine(adjacentCell, false));
				}
			}

			return lineGridCells;
		}

		/// <summary>
		/// Gets all the possible valid moves the given dot GridCell can make
		/// </summary>
		private List<Move> GetPossibleMoves(GridCell fromCell)
		{
			List<Move>		possibleMoves	= new List<Move>();
			List<GridCell>	adjacentCells	= GetAdjacentCells(fromCell);

			for (int i = 0; i < adjacentCells.Count; i++)
			{
				GridCell adjacentCell = adjacentCells[i];

				if (adjacentCell.IsBlock)
				{
					continue;
				}

				if (IsValidPush(fromCell, adjacentCell))
				{
					Move move		= new Move();
					move.moveType	= MoveType.Push;
					move.fromCell	= fromCell;
					move.toCell		= adjacentCell;

					possibleMoves.Add(move);
				}

				if (IsValidJoin(fromCell, adjacentCell))
				{
					Move move		= new Move();
					move.moveType	= MoveType.Join;
					move.fromCell	= fromCell;
					move.toCell		= adjacentCell;

					possibleMoves.Add(move);
				}

				if (IsValidSplit(fromCell, adjacentCell))
				{
					Move move		= new Move();
					move.moveType	= MoveType.Split;
					move.fromCell	= fromCell;
					move.toCell		= adjacentCell;

					possibleMoves.Add(move);
				}
			}

			return possibleMoves;
		}

		private bool IsValidPush(GridCell fromCell, GridCell toCell)
		{
			return
				(fromCell.IsDot && toCell.IsDot && fromCell.lineNumber != toCell.lineNumber) &&	// Check that the fromCell and toCell are both Dots and they are not part of the same line
				!IsCellAdjacentToLineNumber(toCell, fromCell, fromCell.lineNumber, false) &&	// Check that the toCell is not adjacent to a GridCell that has the same line number as fromCell
				GetLineLength(toCell) > 3;
		}

		private bool IsValidJoin(GridCell fromCell, GridCell toCell)
		{
			return
				(fromCell.IsDot && toCell.IsDot && fromCell.lineNumber != toCell.lineNumber) &&	// Check that the fromCell and toCell are both Dots and they are not part of the same line
				(currentNumLines > MinLines || GetLineLength(fromCell) < 3) && 
				!IsCellAdjacentToLineNumber(toCell, fromCell, fromCell.lineNumber, true);		// Check that none of the grid cells belonging to the toCell line are adjacent to the fromCell line
		}

		private bool IsValidSplit(GridCell fromCell, GridCell toCell)
		{
			if (fromCell.IsDot && toCell.IsLineSegment && fromCell.lineNumber != toCell.lineNumber &&
			    currentNumLines < MaxLines &&
			    !IsCellAdjacentToLineNumber(toCell, fromCell, fromCell.lineNumber, false))
			{
				List<GridCell> adjacentLineSegments = GetAdjacentLineSegments(toCell);

				// Sanity check, there should only be two line segments since toCell is a line segment in a valid line
				if (adjacentLineSegments.Count != 2)
				{
					return false;
				}

				// Set toCells line number to -1 temporarily so we can get the length of both lines created by splitting the line at toCell
				int toCellLineNumber = toCell.lineNumber;

				toCell.lineNumber = -1;

				bool isValid = GetLineLength(adjacentLineSegments[0]) > 3 && GetLineLength(adjacentLineSegments[1]) > 3;

				toCell.lineNumber = toCellLineNumber;

				return isValid;
			}

			return false;
		}

		/// <summary>
		/// Gets the length of the line that is part of the given GridCell
		/// </summary>
		private int GetLineLength(GridCell gridCell, bool newMarker = true)
		{
			if (newMarker)
			{
				currentLineLengthMarker++;
			}

			gridCell.lineLengthMarker = currentLineLengthMarker;

			int length = 1;

			List<GridCell> adjacentCells = GetAdjacentCells(gridCell);

			for (int i = 0; i < adjacentCells.Count; i++)
			{
				GridCell adjacentCell = adjacentCells[i];

				if (adjacentCell.lineLengthMarker != currentLineLengthMarker && adjacentCell.lineNumber == gridCell.lineNumber)
				{
					length += GetLineLength(adjacentCell, false);
				}
			}

			return length;
		}

		/// <summary>
		/// Checks if the given GridCell is adjacent to any other GridCell that has the given lineNumber
		/// </summary>
		private bool IsCellAdjacentToLineNumber(GridCell gridCell, GridCell ignoreCell, int lineNumber, bool recursive, bool newMarker = true)
		{
			if (newMarker)
			{
				currentAdjacentMarker++;
			}

			gridCell.adjacentMarker = currentAdjacentMarker;

			List<GridCell> adjacentCells = GetAdjacentCells(gridCell);

			for (int i = 0; i < adjacentCells.Count; i++)
			{
				GridCell adjacentCell = adjacentCells[i];

				if (adjacentCell != ignoreCell && adjacentCell.lineNumber == lineNumber)
				{
					return true;
				}

				if (recursive && adjacentCell.adjacentMarker != currentAdjacentMarker && adjacentCell.lineNumber == gridCell.lineNumber)
				{
					if (IsCellAdjacentToLineNumber(adjacentCell, null, lineNumber, recursive, false))
					{
						return true;
					}
				}
			}

			return false;
		}

		private bool IsValidLineSegment(GridCell gridCell, GridCell fromCell, int lineLength)
		{
			if (gridCell.row == 1 && gridCell.col == 3)
			{
				Log("");
			}

			List<GridCell> adjacentLineSegments = GetAdjacentLineSegments(gridCell);

			if (fromCell != null)
			{
				adjacentLineSegments.Remove(fromCell);
			}

			if (adjacentLineSegments.Count == 0)
			{
				return gridCell.IsDot && lineLength >= 3;
			}

			if (adjacentLineSegments.Count == 1)
			{
				return IsValidLineSegment(adjacentLineSegments[0], gridCell, lineLength + 1);
			}

			return false;
		}

		/// <summary>
		/// Gets the GridCells that are adjacent to the given fromCell GridCell
		/// </summary>
		private List<GridCell> GetAdjacentCells(GridCell fromCell)
		{
			List<GridCell>	adjacentCells		= new List<GridCell>();
			List<int[]>		adjacentPositions	= GetAdjacentCellPositions(fromCell);

			for (int i = 0; i < adjacentPositions.Count; i++)
			{
				GridCell gridCell;

				if (TryGetGridCell(adjacentPositions[i][0], adjacentPositions[i][1], out gridCell))
				{
					adjacentCells.Add(gridCell);
				}
			}

			return adjacentCells;
		}

		/// <summary>
		/// Gets all to row/col positions that are adjacent to the given gridCell
		/// </summary>
		private List<int[]> GetAdjacentCellPositions(GridCell gridCell)
		{
			return new List<int[]>()
			{
				new int[] { gridCell.row, gridCell.col + 1 },
				new int[] { gridCell.row - 1, gridCell.col },
				new int[] { gridCell.row, gridCell.col - 1 },
				new int[] { gridCell.row + 1, gridCell.col}
			};
		}

		/// <summary>
		/// Gets all to row/col positions that are adjacent to the given gridCell
		/// </summary>
		private List<int[]> GetAdjacentCellPositionsForSimpleCase(GridCell gridCell)
		{
			return new List<int[]>()
			{
				new int[] { gridCell.row, gridCell.col + 1 },
				new int[] { gridCell.row - 1, gridCell.col }
				//new int[] { gridCell.row, gridCell.col - 1 },
				//new int[] { gridCell.row + 1, gridCell.col },
			};
		}

		/// <summary>
		/// Tries to get the GridCell from the grid at the given row/col, returns false if the row/col are out of bounds
		/// </summary>
		private bool TryGetGridCell(int row, int col, out GridCell gridCell)
		{
			gridCell = null;

			if (row >= 0 && row < grid.Count && col >= 0 && col < grid[0].Count)
			{
				gridCell = grid[row][col];
			}

			return gridCell != null;
		}

		/// <summary>
		/// Checks if the grid is vaild
		/// </summary>
		private int IsGridValid(bool logError)
		{
			// Check that there are no un-assigned cells or un-connected cells
			for (int r = 0; r < grid.Count; r++)
			{
				for (int c = 0; c < grid[r].Count; c++)
				{
					GridCell gridCell = grid[r][c];

					// Check that there are no un-assigned or un-connected cells
					if (gridCell.IsNotAssigned || gridCell.IsUnConnected)
					{
						if (EnableLogging && logError)
						{
							Log(string.Format("Cell at r:{0}, c:{1} is un-assigned or un-connected", gridCell.row, gridCell.col));
						}

						return 1;
					}

					// Check that all lines are valid (No two segments are beside each other, the line ends in a dot, and the lines length is greater than 2
					if (gridCell.IsDot && !IsValidLineSegment(gridCell, null, 1))
					{
						if (EnableLogging && logError)
						{
							Log(string.Format("Line starting at r:{0}, c:{1} is not valid", gridCell.row, gridCell.col));
						}

						return 2;
					}
				}
			}

			return 0;
		}

		#endregion

		#region Print Methods

		private void Log(string message)
		{
			if (EnableLogging)
			{
				System.IO.File.AppendAllText(LogFilePath, message + "\n");
			}
		}

		private void LogGrid(string header = "")
		{
			if (EnableLogging)
			{
				string prnt = "---" + header + "---\n";

				prnt += PrintGridLineNumbers();
				prnt += "\n---\n";
				prnt += PrintGridTypes();

				Log(prnt);
			}
		}

		public string PrintGridLineNumbers()
		{
			string prnt = "Grid Cell L#:";

			Dictionary<int, char> lineNumChar = new Dictionary<int, char>();

			char nextChar = 'A';

			for (int row = grid.Count - 1; row >= 0; row--)
			{
				List<GridCell> gridRow = grid[row];

				prnt += "\n";

				for (int col = 0; col < gridRow.Count; col++)
				{
					GridCell gridCell = gridRow[col];

					switch (gridCell.cellType)
					{
						case CellType.NotAssigned:
							prnt += " ";
							break;
						case CellType.Block:
							prnt += "#";
							break;
						case CellType.Dot:
						case CellType.LineSegment:
						case CellType.UnConnectedLineSegment:
							if (!lineNumChar.ContainsKey(gridCell.lineNumber))
							{
								lineNumChar.Add(gridCell.lineNumber, nextChar++);
							}

							prnt += lineNumChar[gridCell.lineNumber].ToString();
							break;
					}
				}
			}

			return prnt;
		}

		public string PrintGridTypes()
		{
			string prnt = "Grid Cell Types:";

			for (int row = grid.Count - 1; row >= 0; row--)
			{
				List<GridCell> gridRow = grid[row];

				prnt += "\n";

				for (int col = 0; col < gridRow.Count; col++)
				{
					GridCell gridCell = gridRow[col];

					switch (gridCell.cellType)
					{
						case CellType.NotAssigned:
							prnt += " ";
							break;
						case CellType.Block:
							prnt += "#";
							break;
						case CellType.Dot:
							prnt += "O";
							break;
						case CellType.LineSegment:
							prnt += "-";
							break;
						case CellType.UnConnectedLineSegment:
							prnt += "u";
							break;
					}
				}
			}

			return prnt;
		}

		#endregion
	}
}