using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace BizzyBeeGames.DotConnect
{
	public class LevelSaveData
	{
		#region Member Variables

		public List<List<CellPos>>	placedLineSegments;
		public List<int>			hintLineIndices;
		public int					numMoves;

		#endregion

		#region Public Methods

		public LevelSaveData()
		{
			hintLineIndices = new List<int>();
		}

		public Dictionary<string, object> Save()
		{
			List<List<int>> savedPlacedLineSegments = new List<List<int>>();

			// Loop through each line
			for (int i = 0; i < placedLineSegments.Count; i++)
			{
				List<CellPos> lineSegments = placedLineSegments[i];

				savedPlacedLineSegments.Add(new List<int>());

				// Loop through each lines placed segments
				for (int j = 0; j < lineSegments.Count; j++)
				{
					CellPos placedLineSegment = lineSegments[j];

					savedPlacedLineSegments[i].Add(placedLineSegment.row);
					savedPlacedLineSegments[i].Add(placedLineSegment.col);
				}
			}

			Dictionary<string, object> savedLevelData = new Dictionary<string, object>();

			savedLevelData["placed_line_segments"]	= savedPlacedLineSegments;
			savedLevelData["num_moves"]				= numMoves;
			savedLevelData["hints"]					= hintLineIndices;

			return savedLevelData;
		}

		#endregion
	}
}
