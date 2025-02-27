import processing.core.PVector;

/**
 * Manages camera position, zoom, and transformations.
 * Follows Single Responsibility Principle by focusing on camera operations.
 */
class CameraManager {
    private PVector position;
    private float zoom;
    private final float DEFAULT_ZOOM;  // Will be calculated based on screen size
    private final float MIN_ZOOM;
    private final float MAX_ZOOM;

    CameraManager() {
        position = new PVector();
        // Calculate default zoom to show entire world plus margin
        DEFAULT_ZOOM = (float)width / (GameConfig.World.WINDOW_SIZE * 1.2);
        MIN_ZOOM = DEFAULT_ZOOM;  // Minimum zoom shows entire world
        MAX_ZOOM = 2.0;  // Maximum zoom for detail
        zoom = DEFAULT_ZOOM;  // Start at minimum zoom
    }

    /**
     * Applies the camera transformation for world-space rendering.
     */
    void applyTransform() {
        pushMatrix();
        translate(width / 2, height / 4);
        scale(zoom);
        translate(position.x, position.y);
    }

    /**
     * Resets the camera transformation.
     */
    void resetTransform() {
        popMatrix();
    }

    /**
     * Moves the camera by the specified delta.
     */
    void move(float dx, float dy) {
        position.x += dx / zoom; // Adjust movement based on zoom level
        position.y += dy / zoom;
    }

    /**
     * Sets the camera zoom level with bounds checking.
     */
    void setZoom(float newZoom) {
        zoom = constrain(newZoom, MIN_ZOOM, MAX_ZOOM);
    }

    /**
     * Adjusts zoom by a delta amount.
     */
    void adjustZoom(float delta, float focusX, float focusY) {
        // Store old world position of mouse
        PVector oldWorld = screenToWorld(focusX, focusY);

        // Adjust zoom
        float newZoom = constrain(zoom * (1 + delta), MIN_ZOOM, MAX_ZOOM);
        if (newZoom != zoom) {
            zoom = newZoom;

            // Get new world position of mouse
            PVector newWorld = screenToWorld(focusX, focusY);

            // Adjust position to maintain focus point
            position.x += (newWorld.x - oldWorld.x);
            position.y += (newWorld.y - oldWorld.y);
        }
    }

    /**
     * Gets the current zoom level.
     */
    float getZoom() {
        return zoom;
    }

    /**
     * Gets the current camera position.
     */
    PVector getPosition() {
        return position.copy();
    }

    /**
     * Converts screen coordinates to world coordinates.
     */
    PVector screenToWorld(float screenX, float screenY) {
        // Reverse the camera transformations
        float worldX = (screenX - width / 2) / zoom - position.x;
        float worldY = (screenY - height / 4) / zoom - position.y;
        return new PVector(worldX, worldY);
    }

    /**
     * Converts world coordinates to screen coordinates.
     */
    PVector worldToScreen(float worldX, float worldY) {
        // Apply the camera transformations
        float screenX = (worldX + position.x) * zoom + width / 2;
        float screenY = (worldY + position.y) * zoom + height / 4;
        return new PVector(screenX, screenY);
    }

    /**
     * Resets the camera to its default state.
     */
    void reset() {
        position.set(0, 0);
        zoom = DEFAULT_ZOOM;
    }
}