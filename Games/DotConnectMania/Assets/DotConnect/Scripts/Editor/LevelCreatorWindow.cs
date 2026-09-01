using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

using System.Threading;

namespace BizzyBeeGames.DotConnect
{
	public class LevelCreatorWindow : EditorWindow
	{
		#region Variables

		private Vector2 scrollPosition;

		private int					gridRows		= 5;
		private int					gridCols		= 5;
		private List<List<int>> 	cells			= new List<List<int>>();
		private bool				toggleBlocks	= true;
		private bool				toggleBlanks	= false;

		private int					numMoves		= 1000;
		private int					minLines		= 4;
		private int					maxLines		= 6;
		private bool				batchGeneration	= false;
		private int					numLevels		= 1;
		private int					seed			= 0;
		private Object				outputFolder	= null;
		private string				filenamePrefix	= "";
		private bool				enableLogging	= false;

		private LevelCreatorWorker	worker;
		private int					numLevelsToGenerate;
		private int					numLevelsLeft;

		private Texture2D 			whiteTexture;
		private Texture2D 			blackTexture;
		private Texture2D 			greyTexture;

		#endregion

		#region Properties

		private bool IsWorkerProcessing { get { return worker != null; } }

		private Texture2D WhiteTexture	{ get { return (whiteTexture == null) ? whiteTexture = CreateTexture(Color.white) : whiteTexture; } }
		private Texture2D BlackTexture	{ get { return (blackTexture == null) ? blackTexture = CreateTexture(Color.black) : blackTexture; } }
		private Texture2D GreyTexture	{ get { return (greyTexture == null) ? greyTexture = CreateTexture(Color.grey) : greyTexture; } }

		private string SavedCells
		{
			get { return EditorPrefs.GetString("LevelCreatorWindow.cells", ""); }
			set { EditorPrefs.SetString("LevelCreatorWindow.cells", value); }
		}

		private string OutputFolderAssetPath
		{
			get { return EditorPrefs.GetString("OutputFilderAssetPath", ""); }
			set { EditorPrefs.SetString("OutputFilderAssetPath", value); }
		}

		#endregion

		#region Unity Methods

		[MenuItem ("Window/Dot Connect Level Creator")]
		public static void Init()
		{
			EditorWindow.GetWindow<LevelCreatorWindow>("Level Creator");
		}

		private void OnEnable()
		{
			cells = new List<List<int>>();

			string savedCellsStr = SavedCells;

			if (string.IsNullOrEmpty(savedCellsStr)) 
			{
				CreateCells();
			}
			else
			{
				string[] savedCellsStrSplit = savedCellsStr.Split(',');

				gridRows = System.Convert.ToInt32(savedCellsStrSplit[0]);
				gridCols = System.Convert.ToInt32(savedCellsStrSplit[1]);

				CreateCells();

				for (int i = 2; i < savedCellsStrSplit.Length; i += 3)
				{
					int r = System.Convert.ToInt32(savedCellsStrSplit[i]);
					int c = System.Convert.ToInt32(savedCellsStrSplit[i + 1]);
					int t = System.Convert.ToInt32(savedCellsStrSplit[i + 2]);

					cells[r][c] = t; 
				}
			}

			if (outputFolder == null && !string.IsNullOrEmpty(OutputFolderAssetPath))
			{
				outputFolder = AssetDatabase.LoadAssetAtPath<Object>(OutputFolderAssetPath);
			}
		}

		private void OnDisable()
		{
			if (whiteTexture != null) DestroyImmediate(whiteTexture);
			if (blackTexture != null) DestroyImmediate(blackTexture);
			if (greyTexture != null) DestroyImmediate(greyTexture);

			string cellsStr = string.Format("{0},{1}", gridRows, gridCols);

			for (int r = 0; r < gridRows; r++)
			{
				for (int c = 0; c < gridCols; c++)
				{
					cellsStr += string.Format(",{0},{1},{2}", r, c, cells[r][c]);
				}
			}

			SavedCells = cellsStr;
		}

		private void OnGUI()
		{
			scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition);

			EditorGUILayout.Space();

			// Cannot change values when the worker is working
			GUI.enabled = !IsWorkerProcessing;

			DrawWindow();

			GUI.enabled = true;

			EditorGUILayout.Space();

			EditorGUILayout.EndScrollView();
		}

		private void Update()
		{
			if (IsWorkerProcessing)
			{
				if (worker.Stopped)
				{
					WorkerFinished();
				}
				else
				{
					int		numGenerated	= (numLevelsToGenerate - numLevelsLeft);
					float	percentComplete	= ((float)numGenerated / (float)numLevelsToGenerate);

					bool cancel = EditorUtility.DisplayCancelableProgressBar("Generating Levels", string.Format("Generating level {0} of {1}", (numGenerated + 1), numLevelsToGenerate), percentComplete);
				
					if (cancel)
					{
						worker.Stop();
						worker = null;

						EditorUtility.ClearProgressBar();
					}
				}
			}
		}

		#endregion

		#region Private Methods

		private LevelCreatorWorker GenerateLevel()
		{
			int seedToUse = seed;

			if (seedToUse == 0)
			{
				seedToUse = Random.Range(1, int.MaxValue);
			}

			Random.InitState(seedToUse);

			// Create the worker
			worker = new LevelCreatorWorker();

			worker.NumMoves			= numMoves;
			worker.MinLines			= minLines;
			worker.MaxLines			= maxLines == 0 ? int.MaxValue : maxLines;
			worker.RandSeed 		= seedToUse;
			worker.EnableLogging	= enableLogging;
			worker.LogFilePath		= Application.dataPath + "/level_creator_logs.txt";

			// Create the cell types list
			worker.BlockPositions = new List<List<bool>>();

			for (int i = 0, r = gridRows - 1; r >= 0; r--, i++)
			{
				worker.BlockPositions.Add(new List<bool>());

				for (int c = 0; c < gridCols; c++)
				{
					worker.BlockPositions[i].Add(cells[r][c] != 0); 
				}
			}

			// Start the worker
			new Thread(new ThreadStart(worker.Run)).Start();

			return worker;
		}

		private void WorkerFinished()
		{
			switch (worker.Error)
			{
				case LevelCreatorWorker.ErrorType.InvalidGridCells:
					Debug.LogError("There are un-assigned/un-connected tiles.");
					break;
				case LevelCreatorWorker.ErrorType.InvalidGridLines:
					Debug.LogError("Some lines are not valid.");
					break;
				case LevelCreatorWorker.ErrorType.Exception:
					Debug.LogError("An exception occured");
					break;
			}

			if (worker.Error == LevelCreatorWorker.ErrorType.None)
			{
				Debug.Log(worker.PrintGridLineNumbers());
				WriteLevelToFile();
			}
			else
			{
				switch (worker.Error)
				{
					case LevelCreatorWorker.ErrorType.InvalidGridCells:
						Debug.LogError("There are un-assigned/un-connected tiles.");
						break;
					case LevelCreatorWorker.ErrorType.InvalidGridLines:
						Debug.LogError("Some lines are not valid.");
						break;
					case LevelCreatorWorker.ErrorType.Exception:
						Debug.LogError("An exception occured");
						break;
				}
			}

			worker = null;

			numLevelsLeft--;

			if (numLevelsLeft > 0)
			{
				GenerateLevel();
			}
			else
			{
				EditorUtility.ClearProgressBar();

				EditorUtility.DisplayDialog("Generating Complete", "Finished generating level files. Files are located in " + GetOutputFolderPath(outputFolder).Remove(0, Application.dataPath.Length + 1), "Okay");
			}
		}

		private void WriteLevelToFile()
		{
			Dictionary<string, object> json = new Dictionary<string, object>();

			string id = ((long)Utilities.SystemTimeInMilliseconds).ToString();

			json["rows"]		= gridRows;
			json["cols"]		= gridCols;
			json["cells"]		= cells;
			json["line_coords"]	= worker.GetLineCoordinates();

			string fileName = (string.IsNullOrEmpty(filenamePrefix) ? "" : filenamePrefix + "_") + gridRows + "_" + gridCols + "_" + id;
			string filePath = string.Format("{0}/{1}.json", GetOutputFolderPath(outputFolder), fileName);
			string contents	= id + "\n" + Utilities.ConvertToJsonString(json);

			System.IO.File.WriteAllText(filePath, contents);

			AssetDatabase.Refresh();
		}

		private void CreateCells()
		{
			cells.Clear();

			for (int r = 0; r < gridRows; r++)
			{
				cells.Add(new List<int>());

				for (int c = 0; c < gridCols; c++)
				{
					cells[r].Add(0);
				}
			}
		}

		private Texture2D CreateTexture(Color color)
		{
			Texture2D texture = new Texture2D(1, 1);
			texture.SetPixel(0, 0, color);
			texture.Apply();

			return texture;
		}

		#region Draw Methods

		private void DrawWindow()
		{
			DrawSizeSettings();

			DrawAlgoSettings();

			DrawGenerateButton();
		}

		private void DrawSizeSettings()
		{
			EditorGUILayout.BeginVertical(GUI.skin.box);

			int prevGridRows = gridRows;
			int prevGridCols = gridCols;

			gridRows = Mathf.Max(3, EditorGUILayout.IntField("Rows", gridRows));
			gridCols = Mathf.Max(3, EditorGUILayout.IntField("Columns", gridCols));

			if (gridRows != prevGridRows || gridCols != prevGridCols)
			{
				CreateCells();
			}

			EditorGUILayout.Space();

			DrawGridSettings();
			DrawGrid();

			if (GUILayout.Button("Clear"))
			{
				CreateCells();
			}

			EditorGUILayout.EndVertical();
		}

		private void DrawAlgoSettings()
		{
			EditorGUILayout.BeginVertical(GUI.skin.box);

			numMoves		= Mathf.Max(1, EditorGUILayout.IntField("Number of Iterations", numMoves));
			minLines		= Mathf.Max(2, EditorGUILayout.IntField("Minimum Number of Lines", minLines));
			maxLines		= Mathf.Max(0, EditorGUILayout.IntField("Maximum Number of Lines", maxLines));
			batchGeneration	= EditorGUILayout.Toggle("Batch Generation", batchGeneration);

			if (batchGeneration)
			{
				seed		= 0;
				numLevels	= Mathf.Max(0, EditorGUILayout.IntField("Number of Levels", numLevels));
			}

			if (!batchGeneration)
			{
				seed = Mathf.Max(0, EditorGUILayout.IntField("Seed", seed));
			}

			//enableLogging = EditorGUILayout.Toggle("Enable Logging", enableLogging);
			enableLogging = false;

			if (enableLogging)
			{
				EditorGUILayout.LabelField("Log file will be created and placed in projects root Assets folder.");
			}

			// Max lines cannot be less than min lines
			if (maxLines != 0)
			{
				maxLines = Mathf.Max(maxLines, minLines);
			}

			EditorGUILayout.EndVertical();
		}

		private void DrawGridSettings()
		{
			bool toggled;

			toggled = EditorGUILayout.ToggleLeft("Toggle Blocks", toggleBlocks);

			if (toggled != toggleBlocks && toggled)
			{
				toggleBlocks	= toggled;
				toggleBlanks	= !toggleBlocks;
			}

			toggled = EditorGUILayout.ToggleLeft("Toggle Blanks", toggleBlanks);

			if (toggled != toggleBlanks && toggled)
			{
				toggleBlanks	= toggled;
				toggleBlocks	= !toggleBlanks;
			}
		}

		private void DrawGrid()
		{
			bool wasGUIEnabled	= GUI.enabled;

			float gridPadding	= 10f;
			float cellSpacing	= 2f;
			float maxCellSize	= 50f;
			float gridWidth		= (position.width - 15f) - gridPadding * 2f;
			float gridCellSize	= Mathf.Min(maxCellSize, (gridWidth - cellSpacing * (gridCols - 2)) / (float)gridCols);

			GUIStyle cellStyle			= new GUIStyle();
			cellStyle.fixedHeight		= gridCellSize;
			cellStyle.fixedWidth		= gridCellSize;
			cellStyle.margin			= new RectOffset((int)cellSpacing, (int)cellSpacing, (int)cellSpacing, (int)cellSpacing);
			cellStyle.alignment			= TextAnchor.MiddleCenter;
			cellStyle.normal.background	= WhiteTexture;

			GUIStyle cellBlockStyle				= new GUIStyle(cellStyle);
			cellBlockStyle.normal.background	= BlackTexture;

			GUIStyle cellBlankStyle				= new GUIStyle(cellStyle);
			cellBlankStyle.normal.background	= GreyTexture;

			float rowsMiddle = (float)gridRows / 2f;
			float colsMiddle = (float)gridCols / 2f;

			GUILayout.Space(gridPadding);

			for (int r = 0; r < gridRows; r++)
			{
				GUILayout.BeginHorizontal();

				GUILayout.Space(gridPadding);

				for (int c = 0; c < gridCols; c++)
				{
					int cell = cells[r][c];

					GUIStyle guiStyle = cellStyle;

					switch (cell)
					{
						case 1:
							guiStyle = cellBlockStyle;
							break;
						case 2:
							guiStyle = cellBlankStyle;
							break;
					}

					bool clicked = GUILayout.Button("", guiStyle);

					if (clicked)
					{
						if (toggleBlocks)
						{
							if (cell == 1)
							{
								cells[r][c] = 0;
							}
							else
							{
								cells[r][c] = 1;
							}
						}
						else if (toggleBlanks)
						{
							if (cell == 2)
							{
								cells[r][c] = 0;
							}
							else
							{
								cells[r][c] = 2;
							}
						}
					}
				}

				GUILayout.EndHorizontal();
			}

			GUILayout.Space(gridPadding);
		}

		private void DrawGenerateButton()
		{
			EditorGUILayout.BeginVertical(GUI.skin.box);

			filenamePrefix = EditorGUILayout.TextField("Filename Prefix", filenamePrefix);

			outputFolder = EditorGUILayout.ObjectField("Output Folder", outputFolder, typeof(Object), false);

			OutputFolderAssetPath = (outputFolder != null) ? AssetDatabase.GetAssetPath(outputFolder) : null;

			string buttonName = "Generate Level" + (batchGeneration ? "s" : "");

			if (worker == null && GUILayout.Button(buttonName, GUILayout.Height(20f)))
			{
				numLevelsToGenerate	= batchGeneration ? numLevels : 1;;
				numLevelsLeft		= numLevelsToGenerate;

				GenerateLevel();
			}

			EditorGUILayout.EndVertical();
		}

		/// <summary>
		/// Gets the full path to the output folder
		/// </summary>
		private static string GetOutputFolderPath(Object outputFolder)
		{
			string folderPath = GetFolderPath(outputFolder);

			// If the folder path is null then set the path to the Resources folder
			if (string.IsNullOrEmpty(folderPath))
			{
				folderPath = Application.dataPath + "/Resources";

				if (!System.IO.Directory.Exists(folderPath))
				{
					System.IO.Directory.CreateDirectory(folderPath);
				}
			}

			return folderPath;
		}

		/// <summary>
		/// Gets the folder path.
		/// </summary>
		private static string GetFolderPath(Object folderObject)
		{
			string folderPath = "";

			if (folderObject != null)
			{
				// Get the full system path to the folder
				folderPath = Application.dataPath.Remove(Application.dataPath.Length - "Assets".Length) + UnityEditor.AssetDatabase.GetAssetPath(folderObject);

				// If it's not a folder then set the path to null so the default path is choosen
				if (!System.IO.Directory.Exists(folderPath))
				{
					folderPath = "";
				}
			}

			return folderPath;
		}

		#endregion

		#endregion
	}
}
