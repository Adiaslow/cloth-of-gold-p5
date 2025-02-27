/**
 * Manages all input handling for the game.
 * Follows Single Responsibility Principle by focusing on input processing.
 */
class InputManager {
  private final GameState gameState;
  private final GridManager gridManager;
  private final CameraManager cameraManager;
  private final CoordinateTransformer transformer;
  
  // Input state
  private boolean isDragging;
  private PVector lastMousePos;
  private float zoomSpeed = 0.1;
  // Calculate min zoom to show entire world plus 20% margin
  private float minZoom = (float)width / (GameConfig.World.WINDOW_SIZE * 1.2);
  private float maxZoom = 2.0;  // Allow zooming in to see details
  private float cameraSpeed = 10.0;  // Camera movement speed
  
  // Key states
  private boolean isWPressed = false;
  private boolean isSPressed = false;
  private boolean isAPressed = false;
  private boolean isDPressed = false;
  
  InputManager(GameState gameState, GridManager gridManager, 
              CameraManager cameraManager, CoordinateTransformer transformer) {
    this.gameState = gameState;
    this.gridManager = gridManager;
    this.cameraManager = cameraManager;
    this.transformer = transformer;
    this.lastMousePos = new PVector();
  }
  
  /**
   * Handles mouse pressed events.
   */
  void handleMousePressed() {
    if (mouseButton == CENTER) {
      startDragging();
    } else if (gameState.isInPlacementPhase()) {
      handlePlacementInput();
    }
  }
  
  /**
   * Handles mouse released events.
   */
  void handleMouseReleased() {
    if (mouseButton == CENTER) {
      isDragging = false;
    }
  }
  
  /**
   * Handles mouse dragged events.
   */
  void handleMouseDragged() {
    if (isDragging) {
      updateCameraDrag();
    }
  }
  
  /**
   * Handles mouse wheel events.
   */
  void handleMouseWheel(float delta) {
    updateCameraZoom(delta);
  }
  
  /**
   * Updates camera position based on held keys.
   * Should be called every frame.
   */
  void update() {
    float dx = 0;
    float dy = 0;
    
    if (isWPressed) dy += cameraSpeed;  // Move down to show what's above
    if (isSPressed) dy -= cameraSpeed;  // Move up to show what's below
    if (isAPressed) dx += cameraSpeed;  // Move right to show what's left
    if (isDPressed) dx -= cameraSpeed;  // Move left to show what's right
    
    if (dx != 0 || dy != 0) {
      cameraManager.move(dx, dy);
    }
  }
  
  /**
   * Handles key pressed events.
   */
  void handleKeyPressed() {
    // Update key states
    if (key == 'w' || key == 'W') {
      isWPressed = true;
    }
    if (key == 's' || key == 'S') {
      isSPressed = true;
    }
    if (key == 'a' || key == 'A') {
      isAPressed = true;
    }
    if (key == 'd' || key == 'D') {
      isDPressed = true;
    }

    // Handle other key events
    if (keyCode == ENTER && gameState.isInPlacementPhase()) {
      gameState.endTurn();
    }
  }

  /**
   * Handles key released events.
   */
  void handleKeyReleased() {
    if (key == 'w' || key == 'W') {
      isWPressed = false;
    }
    if (key == 's' || key == 'S') {
      isSPressed = false;
    }
    if (key == 'a' || key == 'A') {
      isAPressed = false;
    }
    if (key == 'd' || key == 'D') {
      isDPressed = false;
    }
  }
  
  /**
   * Starts camera dragging.
   */
  private void startDragging() {
    isDragging = true;
    lastMousePos.x = mouseX;
    lastMousePos.y = mouseY;
  }
  
  /**
   * Updates camera position while dragging.
   */
  private void updateCameraDrag() {
    float dx = (mouseX - lastMousePos.x) / cameraManager.getZoom();
    float dy = (mouseY - lastMousePos.y) / cameraManager.getZoom();
    
    cameraManager.move(dx, dy);
    
    lastMousePos.x = mouseX;
    lastMousePos.y = mouseY;
  }
  
  /**
   * Updates camera zoom level.
   */
  private void updateCameraZoom(float delta) {
    float zoomDelta = -delta * zoomSpeed;
    float currentZoom = cameraManager.getZoom();
    float newZoom = constrain(currentZoom + zoomDelta, minZoom, maxZoom);
    
    // Only update camera if zoom actually changed
    if (newZoom != currentZoom) {
      // Get world position of screen center before zoom
      PVector beforeZoom = transformer.screenToWorld(width/2, height/2);
      
      cameraManager.setZoom(newZoom);
      
      // Get world position of screen center after zoom
      PVector afterZoom = transformer.screenToWorld(width/2, height/2);
      
      // Adjust camera position to keep screen center fixed
      cameraManager.move(afterZoom.x - beforeZoom.x, afterZoom.y - beforeZoom.y);
    }
  }
  
  /**
   * Handles input during the placement phase.
   */
  private void handlePlacementInput() {
    PVector worldPos = transformer.screenToWorld(mouseX, mouseY);
    PVector gridPos = transformer.worldToGrid(worldPos);
    int gridX = floor(gridPos.x);
    int gridY = floor(gridPos.y);
    
    if (!transformer.isValidGridPosition(gridX, gridY)) return;
    
    if (mouseButton == LEFT) {
      handleUnitPlacement(gridX, gridY);
    } else if (mouseButton == RIGHT) {
      handleUnitRemoval(gridX, gridY);
    }
  }
  
  /**
   * Handles unit placement.
   */
  private void handleUnitPlacement(int gridX, int gridY) {
    if (gameState.getPlacedUnits().size() >= GameConfig.Rules.MAX_UNITS_PER_TURN) {
      gameState.setMessage("Can't place more than " + GameConfig.Rules.MAX_UNITS_PER_TURN + " units!");
      return;
    }
    
    PlayerType currentPlayer = (gameState.getCurrentPlayer() == GameState.PLAYER_A) ? 
                             PlayerType.PLAYER_A : PlayerType.PLAYER_B;
    
    if (gridManager.isValidPlacement(gridX, gridY)) {
      Unit newUnit = new Unit(currentPlayer);
      if (gridManager.placeUnit(gridX, gridY, newUnit, currentPlayer)) {
        gameState.addPlacedUnit(new PVector(gridX, gridY));
        gameState.setMessage("");
      }
    }
  }
  
  /**
   * Handles unit removal.
   */
  private void handleUnitRemoval(int gridX, int gridY) {
    if (gridManager.getCurrentCell(gridX, gridY) == gameState.getCurrentPlayer()) {
      for (int i = gameState.getPlacedUnits().size() - 1; i >= 0; i--) {
        PVector pos = gameState.getPlacedUnits().get(i);
        if (pos.x == gridX && pos.y == gridY) {
          gridManager.clearCell(gridX, gridY);
          gameState.removePlacedUnit(pos);
          gameState.setMessage("");
          gridManager.updateTerritories();
          break;
        }
      }
    }
  }
} 