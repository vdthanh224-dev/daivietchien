export const CUSTOM_ROOM_MODES = Object.freeze({
  "2v2": Object.freeze({
    id: "2v2",
    label: "Đấu Trường 2v2",
    lobbySlots: 2,
    matchMaxPlayers: 4,
    sameTeamLobby: true,
  }),
  dynasty_5: Object.freeze({
    id: "dynasty_5",
    label: "Vương Triều 5 người",
    lobbySlots: 5,
    matchMaxPlayers: 5,
    sameTeamLobby: false,
  }),
  dynasty_8: Object.freeze({
    id: "dynasty_8",
    label: "Vương Triều 8 người",
    lobbySlots: 8,
    matchMaxPlayers: 8,
    sameTeamLobby: false,
  }),
});

const IDLE_TTL_MS = 15 * 60 * 1000;
const STARTED_TTL_MS = 5 * 60 * 1000;

export function getCustomRoomMode(modeId) {
  return CUSTOM_ROOM_MODES[String(modeId || "").trim()] || null;
}

export function normalizeRoomCode(rawCode) {
  const cleaned = String(rawCode ?? "").trim().replace(/^#/, "").replace(/\s+/g, "");
  return /^\d{6}$/.test(cleaned) ? cleaned : "";
}

function cleanMember(raw = {}) {
  const userId = String(raw.userId || "").trim().slice(0, 128);
  const userName = String(raw.userName || "Đại Tướng Quân").trim().slice(0, 32) || "Đại Tướng Quân";
  return {
    userId,
    userName,
    level: Math.max(1, Number(raw.level) || 1),
    rankIndex: Math.max(0, Number(raw.rankIndex) || 0),
    rankStars: Math.max(0, Number(raw.rankStars) || 0),
    rankPoints: Math.max(0, Number(raw.rankPoints) || 0),
    title: String(raw.title || "").slice(0, 64),
    profileBg: Math.max(0, Number(raw.profileBg) || 0),
    socket: raw.socket || null,
  };
}

function makeEmptySlot(slotNumber, is2v2) {
  return {
    slotNumber,
    isDragon: is2v2 ? true : slotNumber === 1,
    isEmpty: true,
    isHost: false,
    userId: "",
    userName: "",
    level: 1,
    rankIndex: 0,
    rankStars: 0,
    rankPoints: 0,
    title: "",
    profileBg: 0,
    socket: null,
  };
}

function makeFilledSlot(slotNumber, member, isHost, is2v2) {
  return {
    slotNumber,
    isDragon: is2v2 ? true : slotNumber === 1,
    isEmpty: false,
    isHost: Boolean(isHost),
    userId: member.userId,
    userName: member.userName,
    level: member.level,
    rankIndex: member.rankIndex,
    rankStars: member.rankStars,
    rankPoints: member.rankPoints,
    title: member.title,
    profileBg: member.profileBg,
    socket: member.socket || null,
  };
}

function buildMatchRoomPayload(room, nowTs, isDirectDraft) {
  const mode = getCustomRoomMode(room.modeId) || CUSTOM_ROOM_MODES["2v2"];
  const members = room.slots.filter((slot) => !slot.isEmpty && slot.userId);
  const tsSuffix = Math.floor(nowTs).toString(36).slice(-4);
  const matchRoomId = `rc_${room.code}_${tsSuffix}`;
  const isDynasty = mode.id.startsWith("dynasty_");
  const targetCount = mode.matchMaxPlayers;
  const slots = [];

  if (mode.id === "2v2") {
    // Keep custom 2v2 duo members locked onto the same Dragon team (seats 1 & 3)
    // so battle_2v2's diagonal teammate layout places them as allies while
    // seats 2 & 4 stay open for public opponents / AI fill.
    const seatMemberByNumber = new Map();
    if (members[0]) seatMemberByNumber.set(1, members[0]);
    if (members[1]) seatMemberByNumber.set(3, members[1]);
    for (let seat = 1; seat <= 4; seat += 1) {
      const m = seatMemberByNumber.get(seat);
      const isDragon = seat === 1 || seat === 3;
      if (m) {
        slots.push({
          seatNumber: seat,
          userId: m.userId,
          userName: m.userName,
          rankPoints: m.rankPoints || 0,
          isDragon,
          isAI: false,
          isEmpty: false,
        });
      } else {
        slots.push({
          seatNumber: seat,
          userId: "empty",
          userName: "",
          rankPoints: 0,
          isDragon,
          isAI: false,
          isEmpty: true,
        });
      }
    }
  } else {
    for (let seat = 1; seat <= targetCount; seat += 1) {
      const m = members[seat - 1];
      if (m) {
        slots.push({
          seatNumber: seat,
          userId: m.userId,
          userName: m.userName,
          rankPoints: 0,
          isDragon: seat === 1,
          isAI: false,
          isEmpty: false,
        });
      } else {
        slots.push({
          seatNumber: seat,
          userId: "empty",
          userName: "",
          rankPoints: 0,
          isDragon: seat === 1,
          isAI: false,
          isEmpty: true,
        });
      }
    }
  }

  return {
    roomId: matchRoomId,
    customCode: room.code,
    modeId: mode.id,
    hostUserId: room.hostUserId,
    status: isDirectDraft ? "STARTED" : "WAITING",
    version: 1,
    hostRankPoints: isDynasty ? 0 : (members[0]?.rankPoints || 0),
    slots,
  };
}

/**
 * Merges real players from a source Appwrite waiting room into an anchor room.
 * Custom 2v2 duo pairs (`rc_` rooms with 2 same-team players) stay together on
 * an empty same-team pair `(1,3)` or `(2,4)`, and custom Dynasty parties stay atomic.
 */
export function mergeAppwriteMatchmakingRooms(anchor, source) {
  if (!anchor || !source || !Array.isArray(anchor.slots) || !Array.isArray(source.slots)) {
    return { changed: false, assignedSeats: [] };
  }
  const sourcePlayers = source.slots.filter((slot) => !slot.isEmpty && !slot.isAI && slot.userId && slot.userId !== "empty");
  if (sourcePlayers.length === 0) return { changed: false, assignedSeats: [] };

  const seen = new Set(
    anchor.slots
      .filter((slot) => !slot.isEmpty && !slot.isAI && slot.userId && slot.userId !== "empty")
      .map((slot) => String(slot.userId))
  );
  const newPlayers = sourcePlayers.filter((player) => !seen.has(String(player.userId)));
  if (newPlayers.length === 0) return { changed: false, assignedSeats: [] };

  const modeId = String(anchor.modeId || source.modeId || "2v2");
  const isCustomParty = String(source.roomId || "").startsWith("rc_");

  if (modeId === "2v2" && isCustomParty && newPlayers.length >= 2) {
    // Only consider moving a 2-player same-team duo if anchor has an entire empty team pair.
    const dragonEmpty = [0, 2].every((idx) => anchor.slots[idx] && (anchor.slots[idx].isEmpty || anchor.slots[idx].userId === "empty"));
    const phoenixEmpty = [1, 3].every((idx) => anchor.slots[idx] && (anchor.slots[idx].isEmpty || anchor.slots[idx].userId === "empty"));
    const pairIndices = dragonEmpty ? [0, 2] : (phoenixEmpty ? [1, 3] : null);
    if (!pairIndices) return { changed: false, assignedSeats: [] };
    const targetIsDragon = dragonEmpty;
    const assignedSeats = [];
    for (let i = 0; i < 2; i += 1) {
      const target = anchor.slots[pairIndices[i]];
      Object.assign(target, {
        ...newPlayers[i],
        seatNumber: pairIndices[i] + 1,
        isDragon: targetIsDragon,
        isEmpty: false,
        isAI: false,
      });
      assignedSeats.push(pairIndices[i] + 1);
    }
    return { changed: true, assignedSeats };
  }

  const emptySlots = anchor.slots.filter((slot) => slot.isEmpty || slot.userId === "empty");
  if (isCustomParty && modeId.startsWith("dynasty_") && emptySlots.length < newPlayers.length) {
    return { changed: false, assignedSeats: [] };
  }

  let changed = false;
  const assignedSeats = [];
  for (const player of newPlayers) {
    const target = anchor.slots.find((slot) => slot.isEmpty || slot.userId === "empty");
    if (!target) break;
    const isDragon = modeId === "2v2" ? (Number(target.seatNumber) === 1 || Number(target.seatNumber) === 3) : Boolean(player.isDragon);
    Object.assign(target, {
      ...player,
      seatNumber: Number(target.seatNumber),
      isDragon,
      isEmpty: false,
      isAI: false,
    });
    assignedSeats.push(Number(target.seatNumber));
    seen.add(String(player.userId));
    changed = true;
  }
  return { changed, assignedSeats };
}

export function createCustomRoomStore({ nowFn = () => Date.now(), randomFn = Math.random } = {}) {
  const customRooms = new Map();
  const userToCode = new Map();
  const socketToEntry = new Map();

  function generateUniqueCode() {
    for (let attempt = 0; attempt < 250; attempt += 1) {
      const n = 100000 + Math.floor(randomFn() * 900000);
      const code = String(Math.min(999999, Math.max(100000, n)));
      if (!customRooms.has(code)) return code;
    }
    for (let n = 100000; n <= 999999; n += 1) {
      const code = String(n);
      if (!customRooms.has(code)) return code;
    }
    return "";
  }

  function serializeRoom(room) {
    if (!room) return null;
    const mode = getCustomRoomMode(room.modeId) || CUSTOM_ROOM_MODES["2v2"];
    const memberCount = room.slots.filter((slot) => !slot.isEmpty && slot.userId).length;
    return {
      code: room.code,
      modeId: mode.id,
      modeLabel: mode.label,
      sameTeamLobby: mode.sameTeamLobby,
      lobbySlots: room.slots.length,
      matchMaxPlayers: mode.matchMaxPlayers,
      memberCount,
      hostUserId: room.hostUserId,
      status: room.status,
      matchRoomId: room.matchRoomId || "",
      slots: room.slots.map((slot) => ({
        slotNumber: slot.slotNumber,
        isDragon: slot.isDragon,
        isEmpty: slot.isEmpty,
        isHost: slot.isHost,
        userId: slot.userId,
        userName: slot.userName,
        level: slot.level,
        rankIndex: slot.rankIndex,
        rankStars: slot.rankStars,
        rankPoints: slot.rankPoints,
        title: slot.title,
        profileBg: slot.profileBg,
      })),
    };
  }

  function roomSockets(room) {
    if (!room) return [];
    const seen = new Set();
    const out = [];
    for (const slot of room.slots) {
      if (!slot.isEmpty && slot.socket && !seen.has(slot.socket)) {
        seen.add(slot.socket);
        out.push(slot.socket);
      }
    }
    return out;
  }

  function removeMemberFromRoom(room, userId) {
    if (!room) return { removed: false, closed: false, room: null, removedSocket: null };
    let removedSlot = null;
    for (let i = 0; i < room.slots.length; i += 1) {
      if (!room.slots[i].isEmpty && room.slots[i].userId === userId) {
        removedSlot = room.slots[i];
        room.slots[i] = makeEmptySlot(i + 1, room.modeId === "2v2");
        break;
      }
    }
    if (!removedSlot) return { removed: false, closed: false, room, removedSocket: null };

    if (userToCode.get(userId) === room.code) userToCode.delete(userId);
    if (removedSlot.socket && socketToEntry.get(removedSlot.socket)?.userId === userId) {
      socketToEntry.delete(removedSlot.socket);
    }

    const remaining = room.slots.filter((slot) => !slot.isEmpty && slot.userId);
    if (remaining.length === 0) {
      customRooms.delete(room.code);
      return { removed: true, closed: true, room: null, removedSocket: removedSlot.socket };
    }

    if (room.hostUserId === userId || !remaining.some((slot) => slot.isHost)) {
      remaining[0].isHost = true;
      room.hostUserId = remaining[0].userId;
      for (let i = 1; i < remaining.length; i += 1) remaining[i].isHost = false;
    }
    room.lastActivity = nowFn();
    return { removed: true, closed: false, room, removedSocket: removedSlot.socket };
  }

  function detachExistingRoom(userId, keepCode = "") {
    const prevCode = userToCode.get(userId);
    if (!prevCode || prevCode === keepCode) return null;
    const prevRoom = customRooms.get(prevCode);
    if (!prevRoom) {
      userToCode.delete(userId);
      return null;
    }
    return removeMemberFromRoom(prevRoom, userId);
  }

  function createRoom(rawMember, rawModeId = "2v2") {
    const member = cleanMember(rawMember);
    if (!member.userId) return { ok: false, error: "Chưa đăng nhập tài khoản" };
    const mode = getCustomRoomMode(rawModeId);
    if (!mode) return { ok: false, error: "Chế độ phòng không hợp lệ" };

    const previous = detachExistingRoom(member.userId);
    const code = generateUniqueCode();
    if (!code) return { ok: false, error: "Không còn mã phòng khả dụng, vui lòng thử lại" };

    const nowTs = nowFn();
    const is2v2 = mode.id === "2v2";
    const slots = [];
    for (let s = 1; s <= mode.lobbySlots; s += 1) {
      slots.push(s === 1 ? makeFilledSlot(1, member, true, is2v2) : makeEmptySlot(s, is2v2));
    }

    const room = {
      code,
      modeId: mode.id,
      hostUserId: member.userId,
      status: "WAITING",
      matchRoomId: "",
      createdAt: nowTs,
      lastActivity: nowTs,
      slots,
    };
    customRooms.set(code, room);
    userToCode.set(member.userId, code);
    if (member.socket) socketToEntry.set(member.socket, { code, userId: member.userId });

    return { ok: true, room, previous };
  }

  function joinRoom(rawCode, rawMember) {
    const code = normalizeRoomCode(rawCode);
    if (!code) return { ok: false, error: "Mã phòng phải gồm đúng 6 chữ số" };
    const member = cleanMember(rawMember);
    if (!member.userId) return { ok: false, error: "Chưa đăng nhập tài khoản" };

    const room = customRooms.get(code);
    if (!room) return { ok: false, error: `Không tìm thấy phòng #${code}` };

    const previous = detachExistingRoom(member.userId, code);

    const existing = room.slots.find((slot) => !slot.isEmpty && slot.userId === member.userId);
    if (existing) {
      if (existing.socket && existing.socket !== member.socket) socketToEntry.delete(existing.socket);
      Object.assign(existing, {
        userName: member.userName,
        level: member.level,
        rankIndex: member.rankIndex,
        rankStars: member.rankStars,
        rankPoints: member.rankPoints,
        title: member.title,
        profileBg: member.profileBg,
        socket: member.socket || existing.socket,
      });
      if (member.socket) socketToEntry.set(member.socket, { code, userId: member.userId });
      room.lastActivity = nowFn();
      return { ok: true, room, previous };
    }

    if (room.status !== "WAITING") {
      return { ok: false, error: "Phòng đang tìm trận hoặc trận đấu đã bắt đầu", previous };
    }

    const emptyIdx = room.slots.findIndex((slot) => slot.isEmpty);
    if (emptyIdx < 0) {
      return { ok: false, error: `Phòng #${code} đã đủ người (${room.slots.length}/${room.slots.length})`, previous };
    }

    room.slots[emptyIdx] = makeFilledSlot(emptyIdx + 1, member, false, room.modeId === "2v2");
    userToCode.set(member.userId, code);
    if (member.socket) socketToEntry.set(member.socket, { code, userId: member.userId });
    room.lastActivity = nowFn();
    return { ok: true, room, previous };
  }

  function setMode(rawCode, actorUserId, rawModeId) {
    const code = normalizeRoomCode(rawCode) || userToCode.get(String(actorUserId || "").trim()) || "";
    const room = customRooms.get(code);
    if (!room) return { ok: false, error: "Phòng không còn tồn tại" };
    if (room.hostUserId !== String(actorUserId || "").trim()) {
      return { ok: false, error: "Chỉ chủ phòng mới được đổi chế độ" };
    }
    if (room.status !== "WAITING") {
      return { ok: false, error: "Không thể đổi chế độ khi phòng đang tìm trận" };
    }
    const mode = getCustomRoomMode(rawModeId);
    if (!mode) return { ok: false, error: "Chế độ phòng không hợp lệ" };

    const activeMembers = room.slots.filter((slot) => !slot.isEmpty && slot.userId);
    if (activeMembers.length > mode.lobbySlots) {
      return {
        ok: false,
        error: `Hiện có ${activeMembers.length} người trong phòng, không thể chuyển về ${mode.label} (${mode.lobbySlots} chỗ)`,
      };
    }

    const is2v2 = mode.id === "2v2";
    const nextSlots = [];
    for (let s = 1; s <= mode.lobbySlots; s += 1) {
      const m = activeMembers[s - 1];
      nextSlots.push(m ? makeFilledSlot(s, m, m.isHost || m.userId === room.hostUserId, is2v2) : makeEmptySlot(s, is2v2));
    }
    room.modeId = mode.id;
    room.slots = nextSlots;
    room.lastActivity = nowFn();
    return { ok: true, room };
  }

  function kickMember(rawCode, actorUserId, targetSlotNumber) {
    const code = normalizeRoomCode(rawCode) || userToCode.get(String(actorUserId || "").trim()) || "";
    const room = customRooms.get(code);
    if (!room) return { ok: false, error: "Phòng không còn tồn tại" };
    const actor = String(actorUserId || "").trim();
    if (room.hostUserId !== actor) return { ok: false, error: "Chỉ chủ phòng mới có quyền mời ra" };
    if (room.status !== "WAITING") return { ok: false, error: "Không thể chỉnh sửa khi đang tìm trận" };

    const targetIdx = room.slots.findIndex((slot) => slot.slotNumber === Number(targetSlotNumber));
    if (targetIdx < 0 || room.slots[targetIdx].isEmpty) return { ok: false, error: "Vị trí trống" };
    const targetUid = room.slots[targetIdx].userId;
    if (targetUid === actor) return { ok: false, error: "Không thể tự kick chính mình" };

    const res = removeMemberFromRoom(room, targetUid);
    return { ok: true, room: res.room, kickedUserId: targetUid, kickedSocket: res.removedSocket };
  }

  function leaveRoom(actorUserId, rawCode = "") {
    const uid = String(actorUserId || "").trim();
    const code = normalizeRoomCode(rawCode) || userToCode.get(uid) || "";
    const room = customRooms.get(code);
    if (!room) return { ok: false, closed: false, room: null };
    const res = removeMemberFromRoom(room, uid);
    return { ok: res.removed, closed: res.closed, code, room: res.room, removedSocket: res.removedSocket };
  }

  function handleDisconnect(socket) {
    const entry = socketToEntry.get(socket);
    if (!entry) return null;
    socketToEntry.delete(socket);
    const room = customRooms.get(entry.code);
    if (!room) return null;
    const slot = room.slots.find((s) => !s.isEmpty && s.userId === entry.userId);
    // Keep room if another newer socket already replaced this member.
    if (slot && slot.socket && slot.socket !== socket) return null;
    if (room.status === "WAITING") {
      return { code: entry.code, ...removeMemberFromRoom(room, entry.userId) };
    }
    return null;
  }

  function startRoom(rawCode, actorUserId) {
    const code = normalizeRoomCode(rawCode) || userToCode.get(String(actorUserId || "").trim()) || "";
    const room = customRooms.get(code);
    if (!room) return { ok: false, error: "Phòng không còn tồn tại" };
    const actor = String(actorUserId || "").trim();
    if (room.hostUserId !== actor) return { ok: false, error: "Chỉ chủ phòng mới có quyền bắt đầu" };
    if (room.status !== "WAITING") return { ok: false, error: "Phòng đang tìm trận hoặc đã bắt đầu" };

    const mode = getCustomRoomMode(room.modeId) || CUSTOM_ROOM_MODES["2v2"];
    const members = room.slots.filter((slot) => !slot.isEmpty && slot.userId);
    if (members.length === 0) return { ok: false, error: "Phòng không có người chơi" };

    const nowTs = nowFn();
    const isDirectDraft = !mode.sameTeamLobby && members.length >= mode.matchMaxPlayers;
    const matchRoom = buildMatchRoomPayload(room, nowTs, isDirectDraft);
    room.status = isDirectDraft ? "STARTED" : "MATCHMAKING";
    room.matchRoomId = matchRoom.roomId;
    room.lastActivity = nowTs;

    return {
      ok: true,
      kind: isDirectDraft ? "DIRECT_DRAFT" : "MATCHMAKING",
      room,
      matchRoom,
      targetPlayerCount: mode.matchMaxPlayers,
    };
  }

  function cancelMatchmaking(rawCode, actorUserId) {
    const code = normalizeRoomCode(rawCode) || userToCode.get(String(actorUserId || "").trim()) || "";
    const room = customRooms.get(code);
    if (!room) return { ok: false, error: "Phòng không còn tồn tại" };
    if (room.hostUserId !== String(actorUserId || "").trim()) {
      return { ok: false, error: "Chỉ chủ phòng mới có quyền hủy tìm trận" };
    }
    room.status = "WAITING";
    room.matchRoomId = "";
    room.lastActivity = nowFn();
    return { ok: true, room };
  }

  function redirectMatchmaking(rawCode, actorUserId, newMatchRoomId) {
    const code = normalizeRoomCode(rawCode) || userToCode.get(String(actorUserId || "").trim()) || "";
    const room = customRooms.get(code);
    if (!room) return { ok: false, error: "Phòng không còn tồn tại" };
    if (room.hostUserId !== String(actorUserId || "").trim()) {
      return { ok: false, error: "Chỉ chủ phòng mới có quyền đồng bộ phòng ghép" };
    }
    const cleanTarget = String(newMatchRoomId || "").trim().slice(0, 64);
    if (!cleanTarget) return { ok: false, error: "Thiếu mã phòng ghép đích" };
    room.matchRoomId = cleanTarget;
    room.lastActivity = nowFn();
    return { ok: true, room, matchRoomId: cleanTarget };
  }

  function finishRoomToLobbyCleanup(code) {
    const room = customRooms.get(code);
    if (!room) return;
    for (const slot of room.slots) {
      if (!slot.isEmpty && slot.userId && userToCode.get(slot.userId) === code) {
        userToCode.delete(slot.userId);
      }
      if (slot.socket && socketToEntry.get(slot.socket)?.code === code) {
        socketToEntry.delete(slot.socket);
      }
    }
    customRooms.delete(code);
  }

  function pruneIdle() {
    const nowTs = nowFn();
    const expired = [];
    for (const [code, room] of customRooms.entries()) {
      const ttl = room.status === "STARTED" ? STARTED_TTL_MS : IDLE_TTL_MS;
      if (nowTs - room.lastActivity > ttl) {
        const sockets = roomSockets(room);
        finishRoomToLobbyCleanup(code);
        expired.push({ code, sockets });
      }
    }
    return expired;
  }

  return {
    getRoom: (code) => customRooms.get(normalizeRoomCode(code)) || null,
    getUserRoomCode: (userId) => userToCode.get(String(userId || "").trim()) || "",
    size: () => customRooms.size,
    createRoom,
    joinRoom,
    setMode,
    kickMember,
    leaveRoom,
    handleDisconnect,
    startRoom,
    cancelMatchmaking,
    redirectMatchmaking,
    finishRoomToLobbyCleanup,
    pruneIdle,
    serializeRoom,
    roomSockets,
  };
}
