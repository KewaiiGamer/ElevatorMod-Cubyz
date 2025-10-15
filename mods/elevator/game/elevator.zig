const std = @import("std");

const main = @import("main");
const game = main.game;
const utils = main.utils;
const blocks = main.blocks;
const ServerWorld = main.server.ServerWorld;
const Block = blocks.Block;
const ModelIndex = main.models.ModelIndex;
const vec = main.vec;
const Vec3d = vec.Vec3d;
const Vec3i = vec.Vec3i;
const Player = main.game.Player;
pub var elevator: ?Block = null;

pub const teleportCooldownConstant = 0.3;
pub var teleportCooldown: f64 = 0;

pub fn update(_: f64) void {}
pub fn deinit(_: *main.game.World) void {}
pub fn postDeinit(_: *main.game.World) void {}
pub fn init(_: *main.game.World) void {}
pub fn postInit(_: *main.game.World) void {
}

pub fn findBlockBelowPlayer(pos: @Vector(3, f64)) ?Block {
    const world = main.server.world;
    if (world == null) return null;
    const floorX = @as(i32, @intFromFloat(@floor(pos[0])));
    const floorY = @as(i32, @intFromFloat(@floor(pos[1])));
    const floorZ = @as(i32, @intFromFloat(@floor(pos[2])));
    const block = world.?.getBlock(floorX, floorY, floorZ - 1);
    if (block == null) return null;

    if (block.? != elevator) {
        return null;
    }
    return block;
}
pub fn findNextElevator(world: *ServerWorld, player: @TypeOf(Player), direction: f64, x: f64, y: f64, z: f64) ?f64 {
    if (@abs(z - player.getPosBlocking()[2]) > 10) return null;

    const newZ = z + direction;
    const floorX = @as(i32, @intFromFloat(@floor(x)));
    const floorY = @as(i32, @intFromFloat(@floor(y)));
    const floorZ = @as(i32, @intFromFloat(@floor(newZ)));
    const block = world.getBlock(floorX, floorY, floorZ);
    if (block.? != elevator) {
        return findNextElevator(world, player, direction, x, y, newZ);
    } else {
        return newZ;
    }
}
fn tryTeleportPlayer(key: []const u8) bool {
    const player = main.game.Player;
    const world = main.server.world;
    if (world == null) return false;
    if (teleportCooldown > 0) return false;
    var pos = player.getPosBlocking();
    const block = findBlockBelowPlayer(pos);
    if (block == null) return false;
    var teleportDirection: f64 = 0;
    var startingZ: f64 = pos[2];
    if (std.mem.eql(u8, key, "jump")) {
        teleportDirection = 1;
    } else if (std.mem.eql(u8, key, "fall")) {
        teleportDirection = -1;
        startingZ -= 3;
    }

    const nextElevatorZ = findNextElevator(world.?, player, teleportDirection, pos[0], pos[1], startingZ);
    if (nextElevatorZ == null) {
        return false;
    }

    pos[0] = @floor(pos[0]) + 0.5;
    pos[1] = @floor(pos[1]) + 0.5;
    pos[2] = nextElevatorZ.? + 1;

    teleportCooldown = teleportCooldownConstant;
    player.setPosBlocking(pos);
    return true;
}
pub fn postUpdate(deltaTime: f64) void {
    if (elevator == null) {
        elevator = blocks.parseBlock("elevator:elevator");
    }
    var jumped = false;
    var direction = "none";
    if (main.KeyBoard.key("jump").pressed) {
        jumped = tryTeleportPlayer("jump");
        direction = "jump";
    }
    if (main.KeyBoard.key("fall").pressed) {
        jumped = tryTeleportPlayer("fall");
        direction = "fall";
    }
    teleportCooldown -= deltaTime;
    return;
}