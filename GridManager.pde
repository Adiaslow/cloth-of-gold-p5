/**
 * Manages the game grid, unit placement, and territory calculations.
 * Follows Single Responsibility Principle by focusing on grid operations.
 */
class GridManager {
  // Grid state
  private int[][] currentWorld;
  private int[][] nextWorld;
  private float[][] territoryGridA;
  private float[][] territoryGridB;
  
  // Dependencies
  private final GameState gameState;
  private final TerrainManager terrainManager;
  
  private Unit[][] unitGridA;  // Grid for player A's units
  private Unit[][] unitGridB;  // Grid for player B's units
  
  GridManager(GameState gameState, TerrainManager terrainManager) {
    this.gameState = gameState;
    this.terrainManager = terrainManager;
    initialize();
  }
  
  /**
   * Initializes or resets the grid state.
   */
  void initialize() {
    currentWorld = new int[GameConfig.World.SIZE][GameConfig.World.SIZE];
    nextWorld = new int[GameConfig.World.SIZE][GameConfig.World.SIZE];
    territoryGridA = new float[GameConfig.World.SIZE][GameConfig.World.SIZE];
    territoryGridB = new float[GameConfig.World.SIZE][GameConfig.World.SIZE];
    unitGridA = new Unit[GameConfig.World.SIZE][GameConfig.World.SIZE];
    unitGridB = new Unit[GameConfig.World.SIZE][GameConfig.World.SIZE];
    clearGrids();
  }
  
  /**
   * Clears all grid data.
   */
  private void clearGrids() {
    for (int i = 0; i < GameConfig.World.SIZE; i++) {
      for (int j = 0; j < GameConfig.World.SIZE; j++) {
        currentWorld[i][j] = PlayerType.NONE.getValue();
        nextWorld[i][j] = PlayerType.NONE.getValue();
        territoryGridA[i][j] = 0;
        territoryGridB[i][j] = 0;
      }
    }
  }
  
  /**
   * Updates the grid state for simulation.
   */
  void updateGrid() {
    // Clear next world state
    clearNextWorld();
    
    // Calculate next states
    calculateNextStates();
    
    // Check for stability
    boolean isStable = checkStability();
    
    // Handle stability
    if (isStable && !gameState.isInPlacementPhase()) {
      skipToEndOfDay();
    }
    
    // Swap grids and update territories
    swapGrids();
    updateTerritories();
    
    // Check win conditions
    checkWinConditions();
  }
  
  /**
   * Clears the next world grid.
   */
  private void clearNextWorld() {
    for (int i = 0; i < GameConfig.World.SIZE; i++) {
      for (int j = 0; j < GameConfig.World.SIZE; j++) {
        nextWorld[i][j] = PlayerType.NONE.getValue();
      }
    }
  }
  
  /**
   * Calculates the next state for all cells.
   */
  private void calculateNextStates() {
    for (int i = 0; i < GameConfig.World.SIZE; i++) {
      for (int j = 0; j < GameConfig.World.SIZE; j++) {
        nextWorld[i][j] = calculateNextState(i, j);
      }
    }
  }
  
  /**
   * Calculates the next state for a single cell.
   */
  private char calculateNextState(int x, int y) {
    // Check for water death
    if (isWaterTile(x, y)) {
      return currentWorld[x][y] != PlayerType.NONE.getValue() ? 
             PlayerType.DEAD.getValue() : PlayerType.NONE.getValue();
    }
    
    // Count neighbors
    NeighborCount neighbors = countNeighbors(x, y);
    
    // Apply rules
    return applyRules(x, y, neighbors);
  }
  
  /**
   * Represents the count of different types of neighbors.
   */
  private class NeighborCount {
    int playerA = 0;
    int playerB = 0;
    int neutral = 0;
    
    int getTotal() {
      return playerA + playerB + neutral;
    }
  }
  
  /**
   * Counts the different types of neighbors for a cell.
   */
  private NeighborCount countNeighbors(int x, int y) {
    NeighborCount count = new NeighborCount();
    
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        
        int nx = x + i;
        int ny = y + j;
        
        if (!isValidPosition(nx, ny)) continue;
        
        char cell = (char)currentWorld[nx][ny];
        if (cell == PlayerType.PLAYER_A.getValue()) count.playerA++;
        else if (cell == PlayerType.PLAYER_B.getValue()) count.playerB++;
        else if (cell == PlayerType.NEUTRAL.getValue()) count.neutral++;
      }
    }
    
    return count;
  }
  
  /**
   * Applies the game rules to determine the next state of a cell.
   */
  private char applyRules(int x, int y, NeighborCount neighbors) {
    char currentCell = (char)currentWorld[x][y];
    int total = neighbors.getTotal();
    
    // Standard Game of Life rules for neutral cells
    if (neighbors.playerA == 0 && neighbors.playerB == 0) {
      if (currentCell == PlayerType.NONE.getValue() && total == 3) {
        return PlayerType.NEUTRAL.getValue();
      }
      if (currentCell != PlayerType.NONE.getValue() && (total < 2 || total > 3)) {
        return PlayerType.NONE.getValue();
      }
      return currentCell;
    }
    
    // Cloth of Gold specific rules
    if (total < 2 || total > 3) {
      return PlayerType.NONE.getValue();
    }
    
    if (neighbors.playerA > neighbors.playerB) {
      return PlayerType.PLAYER_A.getValue();
    }
    
    if (neighbors.playerB > neighbors.playerA) {
      return PlayerType.PLAYER_B.getValue();
    }
    
    return currentCell;
  }
  
  /**
   * Updates territory influence for both players.
   */
  void updateTerritories() {
    clearTerritoryGrids();
    calculateTerritoryInfluence(PlayerType.PLAYER_A, territoryGridA);
    calculateTerritoryInfluence(PlayerType.PLAYER_B, territoryGridB);
    resolveTerritoryConflicts();
  }
  
  /**
   * Calculates territory influence for a player.
   */
  private void calculateTerritoryInfluence(PlayerType player, float[][] territoryGrid) {
    ArrayList<PVector> units = getPlayerUnits(player);
    
    for (int i = 0; i < GameConfig.World.SIZE; i++) {
      for (int j = 0; j < GameConfig.World.SIZE; j++) {
        if (isWaterTile(i, j)) continue;
        
        float totalInfluence = 0;
        for (PVector unit : units) {
          float distance = dist(i, j, unit.x, unit.y);
          if (distance <= GameConfig.Rules.MIN_TERRITORY_RADIUS) {
            totalInfluence += 2.0;
          } else if (distance < GameConfig.Rules.TERRITORY_RADIUS) {
            float falloff = 1.0 - ((distance - GameConfig.Rules.MIN_TERRITORY_RADIUS) / 
                                 (GameConfig.Rules.TERRITORY_RADIUS - GameConfig.Rules.MIN_TERRITORY_RADIUS));
            totalInfluence += 2.0 * falloff;
          }
        }
        
        territoryGrid[i][j] = totalInfluence;
      }
    }
  }
  
  /**
   * Gets all units belonging to a player.
   */
  private ArrayList<PVector> getPlayerUnits(PlayerType player) {
    ArrayList<PVector> units = new ArrayList<PVector>();
    for (int i = 0; i < GameConfig.World.SIZE; i++) {
      for (int j = 0; j < GameConfig.World.SIZE; j++) {
        if (currentWorld[i][j] == player.getValue()) {
          units.add(new PVector(i, j));
        }
      }
    }
    return units;
  }
  
  /**
   * Resolves conflicts between overlapping territories.
   */
  private void resolveTerritoryConflicts() {
    for (int i = 0; i < GameConfig.World.SIZE; i++) {
      for (int j = 0; j < GameConfig.World.SIZE; j++) {
        float influenceA = territoryGridA[i][j];
        float influenceB = territoryGridB[i][j];
        float difference = abs(influenceA - influenceB);
        
        if (difference < GameConfig.Rules.TERRITORY_INFLUENCE_THRESHOLD) continue;
        
        if (influenceA > influenceB) {
          territoryGridB[i][j] = 0;
        } else {
          territoryGridA[i][j] = 0;
        }
      }
    }
  }
  
  /**
   * Checks if a position is valid on the grid.
   */
  private boolean isValidPosition(int x, int y) {
    return x >= 0 && x < GameConfig.World.SIZE && 
           y >= 0 && y < GameConfig.World.SIZE;
  }
  
  /**
   * Checks if a tile is water.
   */
  private boolean isWaterTile(int x, int y) {
    return terrainManager.getTerrainType(x, y) == TerrainType.WATER;
  }
  
  /**
   * Checks if the grid state is stable (no changes).
   */
  private boolean checkStability() {
    for (int i = 0; i < GameConfig.World.SIZE; i++) {
      for (int j = 0; j < GameConfig.World.SIZE; j++) {
        if (currentWorld[i][j] != nextWorld[i][j]) {
          return false;
        }
      }
    }
    return true;
  }
  
  /**
   * Swaps the current and next world grids.
   */
  private void swapGrids() {
    int[][] temp = currentWorld;
    currentWorld = nextWorld;
    nextWorld = temp;
  }
  
  /**
   * Checks win conditions.
   */
  private void checkWinConditions() {
    if (!gameState.isInPlacementPhase() && gameState.getCurrentDay() > 1) {
      boolean playerAAlive = hasLivingUnits(PlayerType.PLAYER_A);
      boolean playerBAlive = hasLivingUnits(PlayerType.PLAYER_B);
      
      if (!playerAAlive || !playerBAlive) {
        gameState.handleGameOver(playerAAlive, playerBAlive);
      }
    }
  }
  
  /**
   * Checks if a player has any living units.
   */
  private boolean hasLivingUnits(PlayerType player) {
    for (int i = 0; i < GameConfig.World.SIZE; i++) {
      for (int j = 0; j < GameConfig.World.SIZE; j++) {
        if (currentWorld[i][j] == player.getValue()) {
          return true;
        }
      }
    }
    return false;
  }
  
  /**
   * Skips to the end of the day when grid is stable.
   */
  private void skipToEndOfDay() {
    if (gameState.getPhase() == GamePhase.SIMULATION) {
      gameState.setGeneration(GameConfig.Rules.SIMULATION_GENERATIONS - 1);
    }
  }
  
  /**
   * Checks if a unit exists at the specified position for the given player.
   */
  boolean hasUnit(int x, int y, PlayerType player) {
    if (x < 0 || x >= GameConfig.World.SIZE || y < 0 || y >= GameConfig.World.SIZE) {
      return false;
    }
    
    switch (player) {
      case PLAYER_A:
        return unitGridA[x][y] != null;
      case PLAYER_B:
        return unitGridB[x][y] != null;
      default:
        return false;
    }
  }
  
  /**
   * Gets the unit at the specified position for the given player.
   */
  Unit getUnit(int x, int y, PlayerType player) {
    if (!isValidPosition(x, y)) return null;
    
    return (player == PlayerType.PLAYER_A) ? unitGridA[x][y] : unitGridB[x][y];
  }
  
  /**
   * Places a unit at the specified position.
   */
  boolean placeUnit(int x, int y, Unit unit, PlayerType player) {
    if (!isValidPosition(x, y)) return false;
    if (hasUnit(x, y, PlayerType.PLAYER_A) || hasUnit(x, y, PlayerType.PLAYER_B)) return false;
    
    if (player == PlayerType.PLAYER_A) {
      unitGridA[x][y] = unit;
    } else {
      unitGridB[x][y] = unit;
    }
    
    updateTerritoryInfluence();
    return true;
  }
  
  /**
   * Removes a unit at the specified position.
   */
  void removeUnit(int x, int y, PlayerType player) {
    if (!isValidPosition(x, y)) return;
    
    if (player == PlayerType.PLAYER_A) {
      unitGridA[x][y] = null;
    } else {
      unitGridB[x][y] = null;
    }
    
    updateTerritoryInfluence();
  }
  
  /**
   * Updates territory influence for both players.
   */
  void updateTerritoryInfluence() {
    clearTerritoryGrids();
    
    // Calculate influence for each unit
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        if (unitGridA[x][y] != null) {
          applyTerritoryInfluence(x, y, territoryGridA);
        }
        if (unitGridB[x][y] != null) {
          applyTerritoryInfluence(x, y, territoryGridB);
        }
      }
    }
  }
  
  /**
   * Applies territory influence around a unit.
   */
  private void applyTerritoryInfluence(int unitX, int unitY, float[][] territoryGrid) {
    float radius = GameConfig.Rules.TERRITORY_RADIUS;
    float minRadius = GameConfig.Rules.MIN_TERRITORY_RADIUS;
    
    for (int y = (int)(unitY - radius); y <= unitY + radius; y++) {
      for (int x = (int)(unitX - radius); x <= unitX + radius; x++) {
        if (!isValidPosition(x, y)) continue;
        
        float distance = dist(unitX, unitY, x, y);
        if (distance <= radius) {
          float influence = map(distance, 0, radius, 1, 0);
          if (distance <= minRadius) {
            influence = 1;
          }
          territoryGrid[x][y] = max(territoryGrid[x][y], influence);
        }
      }
    }
  }
  
  /**
   * Gets the territory influence at a position.
   */
  float getTerritoryInfluence(int x, int y, PlayerType player) {
    if (!isValidPosition(x, y)) return 0;
    return (player == PlayerType.PLAYER_A) ? territoryGridA[x][y] : territoryGridB[x][y];
  }
  
  /**
   * Clears territory influence grids.
   */
  private void clearTerritoryGrids() {
    for (int y = 0; y < GameConfig.World.SIZE; y++) {
      for (int x = 0; x < GameConfig.World.SIZE; x++) {
        territoryGridA[x][y] = 0;
        territoryGridB[x][y] = 0;
      }
    }
  }
  
  /**
   * Gets the current cell value at the specified position.
   */
  char getCurrentCell(int x, int y) {
    if (!isValidPosition(x, y)) return PlayerType.NONE.getValue();
    return (char)currentWorld[x][y];
  }
  
  /**
   * Clears a cell at the specified position.
   */
  void clearCell(int x, int y) {
    if (!isValidPosition(x, y)) return;
    currentWorld[x][y] = PlayerType.NONE.getValue();
    if (unitGridA[x][y] != null) unitGridA[x][y] = null;
    if (unitGridB[x][y] != null) unitGridB[x][y] = null;
  }
  
  /**
   * Checks if a unit can be placed at the specified position.
   */
  boolean isValidPlacement(int x, int y) {
    if (!isValidPosition(x, y)) return false;
    if (isWaterTile(x, y)) return false;
    if (hasUnit(x, y, PlayerType.PLAYER_A)) return false;
    if (hasUnit(x, y, PlayerType.PLAYER_B)) return false;
    return true;
  }
} 