/**
 * Represents a unit in the game.
 * Each unit has a type, owner, and position.
 */
class Unit {
  private final UnitType type;
  private final PlayerType owner;
  private PVector position;
  private boolean isAlive;

  /**
   * Creates a new unit with default type and position.
   * @param owner The player who owns this unit
   */
  Unit(PlayerType owner) {
    this(UnitType.WARRIOR, owner, new PVector(0, 0));
  }

  /**
   * Creates a new unit.
   * @param type The type of unit
   * @param owner The player who owns this unit
   * @param position The unit's position on the grid
   */
  Unit(UnitType type, PlayerType owner, PVector position) {
    this.type = type;
    this.owner = owner;
    this.position = position;
    this.isAlive = true;
  }

  /**
   * Gets the unit's type.
   */
  UnitType getType() {
    return type;
  }

  /**
   * Gets the unit's owner.
   */
  PlayerType getOwner() {
    return owner;
  }

  /**
   * Gets the unit's position.
   */
  PVector getPosition() {
    return position;
  }

  /**
   * Sets the unit's position.
   */
  void setPosition(PVector newPosition) {
    this.position = newPosition;
  }

  /**
   * Checks if the unit is alive.
   */
  boolean isAlive() {
    return isAlive;
  }

  /**
   * Marks the unit as dead.
   */
  void die() {
    isAlive = false;
  }
} 