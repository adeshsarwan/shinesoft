using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace BizzyBeeGames.DotConnect
{
	public class LevelData
	{
		// Used for undo
		public List<List<CellPos>>	undoPlacedLineSegments;
		public int					undoNumMoves;
		public int					undoLastChangedLineIndex;

		#region Member Variables

		private TextAsset			levelFile;
		private string				levelFileText;
		private bool				isIdParsed;
		private bool				isFileParsed;

		private string				id;
		private int					gridRows;
		private int					gridCols;
		private List<List<int>>		gridCells;
		private List<List<CellPos>>	linePositions;

		#endregion

		#region Properties

		public string	PackId		{ get; private set; }
		public int		LevelIndex	{ get; private set; }

		public string				Id				{ get { if (!isIdParsed) ParseLevelId(); return id; } }
		public int					GridRows		{ get { if (!isFileParsed) ParseLevelFile(); return gridRows; } }
		public int					GridCols		{ get { if (!isFileParsed) ParseLevelFile(); return gridCols; } }
		public List<List<int>>		GridCells		{ get { if (!isFileParsed) ParseLevelFile(); return gridCells; } }
		public List<List<CellPos>>	LinePositions	{ get { if (!isFileParsed) ParseLevelFile(); return linePositions; } }

		private string LevelFileText
		{
			get
			{
				if (string.IsNullOrEmpty(levelFileText) && levelFile != null)
				{
					levelFileText	= levelFile.text;
					levelFile		= null;
				}

				return levelFileText;
			}
		}

		#endregion

		#region Constructor

		public LevelData(TextAsset levelFile, string packId, int levelIndex)
		{
			this.levelFile	= levelFile;
			PackId			= packId;
			LevelIndex		= levelIndex;
		}

		#endregion

		#region Private Methods

		/// <summary>
		/// Gets the Id only from the level file. The id will be the first line in the level file.
		/// </summary>
		private void ParseLevelId()
		{
			if (isIdParsed) return;

			string	levelFileContents = LevelFileText;
			int		firstNewlineIndex = levelFileContents.IndexOf('\n');

			if (firstNewlineIndex > 0)
			{
				id = levelFileContents.Substring(0, firstNewlineIndex);
			}

			isIdParsed = true;
		}

		/// <summary>
		/// Parse the json in the level file
		/// </summary>
		private void ParseLevelFile()
		{
			if (isFileParsed) return;

			string	levelFileContents = LevelFileText;
			int		firstNewlineIndex = levelFileContents.IndexOf('\n');

			if (firstNewlineIndex >= 0)
			{
				string jsonText = levelFileContents.Substring(firstNewlineIndex + 1);

				JSONNode json = JSON.Parse(jsonText);
				
				gridRows		= json["rows"].AsInt;
				gridCols		= json["cols"].AsInt;
				gridCells		= ParseGridCells(json["cells"].AsArray);
				linePositions	= ParseLinePositions(json["line_coords"].AsArray);
			}

			isFileParsed = true;
		}

		/// <summary>
		/// Parses the line coordinates for each line
		/// </summary>
		private List<List<int>> ParseGridCells(JSONArray cellsJson)
		{
			List<List<int>> cells = new List<List<int>>();

			for (int i = 0; i < cellsJson.Count; i++)
			{
				JSONArray	cellsRowJson	= cellsJson[i].AsArray;
				List<int>	cellsRow		= new List<int>();

				for (int j = 0; j < cellsRowJson.Count; j++)
				{
					cellsRow.Add(cellsRowJson[j].AsInt);
				}

				cells.Add(cellsRow);
			}

			return cells;
		}

		/// <summary>
		/// Parses the line coordinates for each line
		/// </summary>
		private List<List<CellPos>> ParseLinePositions(JSONArray allLineCoordsJson)
		{
			List<List<CellPos>> allLinePositions = new List<List<CellPos>>();

			for (int i = 0; i < allLineCoordsJson.Count; i++)
			{
				JSONArray		lineCoordsJson	= allLineCoordsJson[i].AsArray;
				List<CellPos>	positions		= new List<CellPos>();

				for (int j = 0; j < lineCoordsJson.Count; j += 2)
				{
					positions.Add(new CellPos(lineCoordsJson[j].AsInt, lineCoordsJson[j + 1].AsInt) );
				}

				allLinePositions.Add(positions);
			}

			return allLinePositions;
		}

		#endregion
	}
}
