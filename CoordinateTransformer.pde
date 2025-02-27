/**
 * Handles coordinate transformations between different spaces.
 */
class CoordinateTransformer {
  private final GameState gameState;
  private final CameraManager cameraManager;

  CoordinateTransformer(GameState gameState, CameraManager cameraManager) {
    this.gameState = gameState;
    this.cameraManager = cameraManager;
  }

  /**
   * Converts screen coordinates to world coordinates.
   */
  PVector screenToWorld(float screenX, float screenY) {
    // Convert screen coordinates to world coordinates
    PVector camPos = cameraManager.getPosition();
    float worldX = (screenX - width / 2) / cameraManager.getZoom() - camPos.x;
    float worldY = (screenY - height / 4) / cameraManager.getZoom() - camPos.y;
    return new PVector(worldX, worldY);
  }

  /**
   * Converts world coordinates to grid coordinates (PVector version).
   */
  PVector worldToGrid(PVector worldPos) {
    return worldToGrid(worldPos.x, worldPos.y);
  }

  /**
   * Converts world coordinates to grid coordinates (float version).
   */
  PVector worldToGrid(float worldX, float worldY) {
    float cellSize = gameState.WINDOW_SIZE / (float) gameState.WORLD_SIZE;
    float gridX = worldX / cellSize;
    float gridY = worldY / cellSize;
    return new PVector(gridX, gridY);
  }

  /**
   * Converts grid coordinates to isometric coordinates.
   */
  PVector gridToIsometric(int gridX, int gridY) {
    float cellSize = gameState.WINDOW_SIZE / (float) gameState.WORLD_SIZE;
    float isoX = (gridX - gridY) * cellSize * 0.5f;
    float isoY = (gridX + gridY) * cellSize * 0.25f;
    return new PVector(isoX, isoY);
  }

  /**
   * Checks if a position is valid on the grid.
   */
  boolean isValidGridPosition(int x, int y) {
    return x >= 0 && x < gameState.WORLD_SIZE &&
        y >= 0 && y < gameState.WORLD_SIZE;
  }

  /**
   * Applies the world transformation matrix.
   */
  void applyWorldTransform() {
    translate(width / 2, height / 4);
    scale(cameraManager.getZoom());
    PVector camPos = cameraManager.getPosition();
    translate(camPos.x, camPos.y);
  }
}