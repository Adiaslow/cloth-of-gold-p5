/**
 * Manages all rendering operations for the game.
 */
class DisplayManager {
  private final TerrainRenderer terrainRenderer;
  private final TerritoryRenderer territoryRenderer;
  private final UnitRenderer unitRenderer;
  private final UIRenderer uiRenderer;
  private final RenderConfig config;
  private final CoordinateTransformer coordinateTransformer;
  private final CameraManager cameraManager;
  private final TerrainManager terrainManager;

  DisplayManager(GameState gameState, TerrainManager terrainManager, CameraManager cameraManager) {
    this.cameraManager = cameraManager;
    this.terrainManager = terrainManager;
    this.config = new RenderConfig(gameState);
    this.terrainRenderer = new TerrainRenderer(config);
    this.territoryRenderer = new TerritoryRenderer(config, terrainManager, cameraManager);
    this.unitRenderer = new UnitRenderer(config, terrainManager);
    this.uiRenderer = new UIRenderer(config);
    this.coordinateTransformer = new CoordinateTransformer(gameState, cameraManager);
  }

  /**
   * Renders a complete frame of the game.
   */
  void draw(GameState gameState, GridManager grid, TimeManager timeManager) {
    // Get light level from time manager
    float lightLevel = timeManager.getLightLevel();

    // Set background color based on time of day
    background(config.calculateSkyColor(timeManager.getAdjustedTime()));

    // Apply camera transform for world space rendering
    cameraManager.applyTransform();

    // Draw world elements
    terrainRenderer.draw(terrainManager);
    territoryRenderer.draw(grid);
    unitRenderer.draw(grid, lightLevel);

    // Reset camera for UI rendering
    cameraManager.resetTransform();

    // Draw UI elements
    uiRenderer.draw(gameState, timeManager);

    // Draw placement preview if in placement phase
    if (gameState.getPhase() == GamePhase.PLACEMENT) {
      PVector mouseWorld = cameraManager.screenToWorld(mouseX, mouseY);
      PVector gridPos = coordinateTransformer.worldToGrid(mouseWorld);
      uiRenderer.drawPlacementPreview(gameState, grid, gridPos, lightLevel);
    }

    // Draw debug info if enabled
    if (gameState.debugMode) {
      PVector worldPos = cameraManager.screenToWorld(mouseX, mouseY);
      PVector gridPos = coordinateTransformer.worldToGrid(worldPos);
      uiRenderer.showDebugInfo(mouseX, mouseY, worldPos, gridPos);
    }
  }

  /**
   * Gets the UI renderer for direct UI operations.
   */
  UIRenderer getUIRenderer() {
    return uiRenderer;
  }

  /**
   * Gets the coordinate transformer.
   */
  CoordinateTransformer getCoordinateTransformer() {
    return coordinateTransformer;
  }

  /**
   * Gets the camera manager.
   */
  CameraManager getCameraManager() {
    return cameraManager;
  }
}

/**
 * Configuration class for rendering parameters.
 */
class RenderConfig {
  final GameState gameState;

  RenderConfig(GameState gameState) {
    this.gameState = gameState;
  }

  color calculateSkyColor(float adjustedTime) {
    color skyNight = color(GameConfig.VisualValues.SKY_NIGHT_VALUE);
    color skyDay = color(GameConfig.VisualValues.SKY_DAY_VALUE);
    color skyDawn = color(GameConfig.VisualValues.SKY_DAWN_RGB[0],
                         GameConfig.VisualValues.SKY_DAWN_RGB[1],
                         GameConfig.VisualValues.SKY_DAWN_RGB[2]);
    color skyDusk = color(GameConfig.VisualValues.SKY_DUSK_RGB[0],
                         GameConfig.VisualValues.SKY_DUSK_RGB[1],
                         GameConfig.VisualValues.SKY_DUSK_RGB[2]);

    if (adjustedTime < GameConfig.Time.DAWN_START) { // Night to Dawn
      return lerpColor(skyNight, skyDawn, 
                      map(adjustedTime, 0, 0.15, 0, 1));
    } else if (adjustedTime < GameConfig.Time.DAY_START) { // Dawn to Day
      return lerpColor(skyDawn, skyDay, 
                      map(adjustedTime, 0.15, 0.25, 0, 1));
    } else if (adjustedTime < GameConfig.Time.DUSK_START) { // Day
      return skyDay;
    } else if (adjustedTime < GameConfig.Time.NIGHT_START) { // Day to Dusk
      return lerpColor(skyDay, skyDusk, 
                      map(adjustedTime, 0.75, 0.85, 0, 1));
    } else { // Dusk to Night
      return lerpColor(skyDusk, skyNight, 
                      map(adjustedTime, 0.85, 1, 0, 1));
    }
  }

  float calculateLightLevel(float adjustedTime) {
    if (adjustedTime < GameConfig.Time.DAWN_START)
      return map(adjustedTime, 0, 0.15, 0.3, 0.7);
    if (adjustedTime < GameConfig.Time.DAY_START)
      return map(adjustedTime, 0.15, 0.25, 0.7, 1);
    if (adjustedTime < GameConfig.Time.DUSK_START)
      return 1;
    if (adjustedTime < GameConfig.Time.NIGHT_START)
      return map(adjustedTime, 0.75, 0.85, 1, 0.7);
    return map(adjustedTime, 0.85, 1, 0.7, 0.3);
  }

  boolean isNightTime(float adjustedTime) {
    return adjustedTime < GameConfig.Time.DAWN_START || 
           adjustedTime > GameConfig.Time.NIGHT_START;
  }
}