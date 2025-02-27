/**
 * Manages the core game state and rules.
 * Follows Single Responsibility Principle by focusing on game state management.
 */
class GameState {
  // Game constants
  static final int WORLD_SIZE = 64;
  static final int WINDOW_SIZE = 800;
  static final int SIMULATION_GENERATIONS = 100;
  static final int MAX_UNITS_PER_TURN = 10;

  // Player identifiers
  static final char EMPTY = 0;
  static final char PLAYER_A = 'A';
  static final char PLAYER_B = 'B';
  static final char NEUTRAL = 'N';
  static final char DEAD = 'D';

  // Game state
  private int currentDay;
  private char currentPlayer;
  private boolean isPlacementPhase;
  private String message;
  private ArrayList<PVector> placedThisTurn;
  private GamePhase currentPhase;
  private GridManager grid;
  private TerrainManager terrainManager;

  // Player stats
  int playerAUnitCount;
  int playerBUnitCount;
  float playerATerritoryPercent;
  float playerBTerritoryPercent;

  // Resources
  int playerAResources;
  int playerBResources;

  public boolean debugMode;  // Debug flag

  GameState(TerrainManager terrainManager) {  // Update constructor
    this.terrainManager = terrainManager;
    grid = new GridManager(this, terrainManager);
    initialize();
    debugMode = false;
  }

  /**
   * Initializes or resets the game state.
   */
  void initialize() {
    currentDay = 1;
    currentPlayer = PLAYER_A;
    isPlacementPhase = true;
    message = "";
    placedThisTurn = new ArrayList<PVector>();
    currentPhase = GamePhase.PLACEMENT;

    // Initialize resources
    playerAResources = GameConfig.Resources.STARTING_RESOURCES;
    playerBResources = GameConfig.Resources.STARTING_RESOURCES;

    resetStats();
  }

  /**
   * Resets player statistics.
   */
  void resetStats() {
    playerAUnitCount = 0;
    playerBUnitCount = 0;
    playerATerritoryPercent = 0;
    playerBTerritoryPercent = 0;
  }

  /**
   * Updates territory percentages based on grid state.
   */
  void updateTerritoryPercentages(GridManager grid) {
    int totalCells = WORLD_SIZE * WORLD_SIZE;
    int playerACells = 0;
    int playerBCells = 0;

    for (int y = 0; y < WORLD_SIZE; y++) {
      for (int x = 0; x < WORLD_SIZE; x++) {
        if (grid.territoryGridA[x][y] > 0 && grid.territoryGridB[x][y] <= 0) {
          playerACells++;
        } else if (grid.territoryGridB[x][y] > 0 && grid.territoryGridA[x][y] <= 0) {
          playerBCells++;
        }
      }
    }

    playerATerritoryPercent = (playerACells * 100.0f) / totalCells;
    playerBTerritoryPercent = (playerBCells * 100.0f) / totalCells;
  }

  /**
   * Updates unit counts based on grid state.
   */
  void updateUnitCounts(GridManager grid) {
    playerAUnitCount = 0;
    playerBUnitCount = 0;

    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        if (grid.hasUnit(x, y, PlayerType.PLAYER_A)) {
          playerAUnitCount++;
        }
        if (grid.hasUnit(x, y, PlayerType.PLAYER_B)) {
          playerBUnitCount++;
        }
      }
    }
  }

  /**
   * Updates the game state.
   */
  void update() {
    switch (currentPhase) {
      case PLACEMENT:
        handlePlacementPhase();
        break;
      case SIMULATION:
        handleSimulationPhase();
        break;
      case GAME_OVER:
        handleGameOver(playerAUnitCount > 0, playerBUnitCount > 0);
        break;
    }
  }

  /**
   * Handles the end of a player's turn.
   */
  void endTurn() {
    if (currentPhase != GamePhase.PLACEMENT)
      return;

    if (placedThisTurn.isEmpty()) {
      message = "Must place at least one unit!";
      return;
    }

    currentPlayer = (currentPlayer == PLAYER_A) ? PLAYER_B : PLAYER_A;
    placedThisTurn.clear();
    message = "";

    // Check if both players have placed units
    if (currentPlayer == PLAYER_A) {
      currentDay++;
      if (currentDay > 1) {
        startSimulation();
      }
    }
  }

  /**
   * Starts the simulation phase.
   */
  private void startSimulation() {
    currentPhase = GamePhase.SIMULATION;
    isPlacementPhase = false;
  }

  /**
   * Handles game over condition.
   * @param playerAAlive whether player A has any living units
   * @param playerBAlive whether player B has any living units
   */
  void handleGameOver(boolean playerAAlive, boolean playerBAlive) {
    currentPhase = GamePhase.GAME_OVER;
    if (!playerAAlive && !playerBAlive) {
      message = "Game Over - Draw!";
    } else if (!playerAAlive) {
      message = "Game Over - Player B Wins!";
    } else if (!playerBAlive) {
      message = "Game Over - Player A Wins!";
    }
  }

  /**
   * Gets the current game phase.
   */
  GamePhase getPhase() {
    return currentPhase;
  }

  /**
   * Gets the current player.
   */
  char getCurrentPlayer() {
    return currentPlayer;
  }

  /**
   * Gets the current day.
   */
  int getCurrentDay() {
    return currentDay;
  }

  /**
   * Gets the current message.
   */
  String getMessage() {
    return message;
  }

  /**
   * Sets a game message.
   */
  void setMessage(String msg) {
    message = msg;
  }

  /**
   * Gets the list of units placed this turn.
   */
  ArrayList<PVector> getPlacedUnits() {
    return placedThisTurn;
  }

  /**
   * Adds a placed unit to the current turn.
   */
  void addPlacedUnit(PVector position) {
    placedThisTurn.add(position);
  }

  /**
   * Removes a placed unit from the current turn.
   */
  void removePlacedUnit(PVector position) {
    placedThisTurn.remove(position);
  }

  /**
   * Checks if the game is in placement phase.
   */
  boolean isInPlacementPhase() {
    return isPlacementPhase;
  }

  /**
   * Switches to the next player's turn.
   */
  void switchPlayer() {
    currentPlayer = (currentPlayer == PLAYER_A) ? PLAYER_B : PLAYER_A;
  }

  /**
   * Checks if the game should end.
   */
  boolean checkGameOver() {
    return playerAUnitCount == 0 || playerBUnitCount == 0;
  }

  /**
   * Gets the resources for the current player.
   */
  int getCurrentPlayerResources() {
    return (currentPlayer == PLAYER_A) ? playerAResources : playerBResources;
  }

  /**
   * Sets resources for the current player.
   */
  void setCurrentPlayerResources(int amount) {
    if (currentPlayer == PLAYER_A) {
      playerAResources = amount;
    } else {
      playerBResources = amount;
    }
  }

  /**
   * Toggles debug mode.
   */
  void toggleDebugMode() {
    debugMode = !debugMode;
  }

  /**
   * Handles the placement phase of the game.
   * During this phase, players take turns placing units on the grid.
   */
  private void handlePlacementPhase() {
    // Check if maximum units have been placed for the turn
    if (placedThisTurn.size() >= MAX_UNITS_PER_TURN) {
      message = "Maximum units placed for this turn";
      return;
    }

    // Check if player has enough resources
    if (getCurrentPlayerResources() < GameConfig.Resources.UNIT_COST) {
      message = "Not enough resources to place more units";
      return;
    }

    // Update message for current player's turn if no other message is set
    if (message.isEmpty()) {
      message = "Player " + currentPlayer + "'s turn to place units";
    }

    // Update territory and unit counts
    updateTerritoryPercentages(grid);
    updateUnitCounts(grid);
  }

  /**
   * Handles the simulation phase of the game.
   * During this phase, units interact according to game rules.
   */
  private void handleSimulationPhase() {
    // Update grid state for simulation
    grid.updateGrid();
    
    // Update territory and unit counts
    updateTerritoryPercentages(grid);
    updateUnitCounts(grid);
    
    // Check for game over conditions
    if (checkGameOver()) {
      currentPhase = GamePhase.GAME_OVER;
      handleGameOver(playerAUnitCount > 0, playerBUnitCount > 0);
    }
    
    // Update resources based on territory control
    int territoryIncomeA = (int)(playerATerritoryPercent * GameConfig.Resources.TERRITORY_INCOME);
    int territoryIncomeB = (int)(playerBTerritoryPercent * GameConfig.Resources.TERRITORY_INCOME);
    
    playerAResources = Math.min(playerAResources + territoryIncomeA, GameConfig.Resources.RESOURCE_CAP);
    playerBResources = Math.min(playerBResources + territoryIncomeB, GameConfig.Resources.RESOURCE_CAP);
    
    // Update message with simulation status
    message = "Day " + currentDay + " - Simulating...";
  }

  /**
   * Sets the current simulation generation.
   * @param generation the generation number to set
   */
  void setGeneration(int generation) {
    if (currentPhase == GamePhase.SIMULATION) {
      // If we've reached the end of simulation, move to next day
      if (generation >= SIMULATION_GENERATIONS - 1) {
        currentDay++;
        currentPhase = GamePhase.PLACEMENT;
        isPlacementPhase = true;
        message = "Day " + currentDay + " - Placement Phase";
      }
    }
  }
}

/**
 * Represents different phases of the game.
 */
enum GamePhase {
  PLACEMENT, // Players are placing units
  SIMULATION, // Battle simulation is running
  GAME_OVER // Game has ended
}