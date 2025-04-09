// New file: functions/src/tournaments.ts
// Version: 1.0.0
// Created: April 2025

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Creates a new weekly tournament
 * Runs every Sunday at 12:01 AM
 */
export const createWeeklyTournament = functions.pubsub
  .schedule("1 0 * * 0")
  .timeZone("America/New_York")
  .onRun(async () => {
    const now = new Date();
    
    // Calculate start and end dates
    const startDate = new Date(now);
    const endDate = new Date(now);
    endDate.setDate(endDate.getDate() + 6); // Tournament runs Sunday to Saturday
    endDate.setHours(23, 59, 59, 999);
    
    // Set any active tournaments to completed
    const activeQuery = await db.collection("tournaments")
      .where("status", "==", "active")
      .get();
    
    const batch = db.batch();
    
    activeQuery.forEach((doc) => {
      batch.update(doc.ref, { status: "completed" });
    });
    
    // Calculate total subscribers for prize pool
    const subscribersQuery = await db.collection("users")
      .where("subscriptionStatus", "==", "active")
      .get();
    
    const subscriberCount = subscribersQuery.size;
    const totalPrizePool = subscriberCount * 18; // $18 of $20 subscription (90%)
    
    // Create default payout structure
    const payoutStructure = [
      { rank: 1, percentOfPool: 0.25 }, // 25% to first place
      { rank: 2, percentOfPool: 0.15 }, // 15% to second place 
      { rank: 3, percentOfPool: 0.05 }  // 5% to third place
    ];
    
    // Add remaining top 5% distribution
    const top5Percent = Math.max(Math.ceil(subscriberCount * 0.05), 3);
    const remainingPool = 0.55; // 55% remaining after top 3
    
    if (top5Percent > 3) {
      const remainingWinners = top5Percent - 3;
      const amountPerWinner = remainingPool / remainingWinners;
      
      for (let i = 4; i <= top5Percent; i++) {
        payoutStructure.push({
          rank: i,
          percentOfPool: amountPerWinner
        });
      }
    }
    
    // Create new tournament
    const tournamentRef = db.collection("tournaments").doc();
    batch.set(tournamentRef, {
      startDate: admin.firestore.Timestamp.fromDate(startDate),
      endDate: admin.firestore.Timestamp.fromDate(endDate),
      status: "active",
      participantCount: 0,
      totalPrizePool: totalPrizePool,
      payoutStructure: payoutStructure,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    await batch.commit();
    
    functions.logger.info(`Created new weekly tournament for ${startDate.toDateString()} to ${endDate.toDateString()} with prize pool $${totalPrizePool}`);
    
    return null;
  });

/**
 * Process bet results when game scores are updated
 */
export const processBetResults = functions.firestore
  .document("scores/{scoreId}")
  .onWrite(async (change, context) => {
    const scoreData = change.after.data();
    if (!scoreData) return null;
    
    const gameId = context.params.scoreId;
    const homeScore = scoreData.homeScore;
    const awayScore = scoreData.awayScore;
    
    // Get all pending bets for this game
    const betsSnapshot = await db.collection("bets")
      .where("gameId", "==", gameId)
      .where("status", "==", "pending")
      .get();
    
    if (betsSnapshot.empty) {
      functions.logger.info(`No pending bets found for game ${gameId}`);
      return null;
    }
    
    const batch = db.batch();
    const leaderboardUpdates = new Map();
    
    functions.logger.info(`Processing ${betsSnapshot.size} bets for game ${gameId}`);
    
    // Process each bet
    for (const betDoc of betsSnapshot.docs) {
      const bet = betDoc.data();
      const userId = bet.userId;
      const tournamentId = bet.tournamentId;
      const amount = bet.amount;
      const isHomeTeam = bet.isHomeTeam;
      const initialSpread = bet.initialSpread;
      
      // Calculate if bet won based on spread
      let didWin = false;
      if (isHomeTeam) {
        // User bet on home team
        didWin = (homeScore + initialSpread) > awayScore;
      } else {
        // User bet on away team
        didWin = (awayScore + initialSpread) > homeScore;
      }
      
      // Update bet status
      batch.update(betDoc.ref, {
        status: didWin ? "won" : "lost",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Track leaderboard updates
      const leaderboardKey = `${userId}_${tournamentId}`;
      if (!leaderboardUpdates.has(leaderboardKey)) {
        // Get current leaderboard entry
        const leaderboardQuery = await db.collection("leaderboard")
          .where("userId", "==", userId)
          .where("tournamentId", "==", tournamentId)
          .limit(1)
          .get();
        
        if (!leaderboardQuery.empty) {
          leaderboardUpdates.set(leaderboardKey, {
            ref: leaderboardQuery.docs[0].ref,
            coinsWon: 0,
            betsWon: 0
          });
        }
      }
      
      if (leaderboardUpdates.has(leaderboardKey)) {
        const update = leaderboardUpdates.get(leaderboardKey);
        if (didWin) {
          update.coinsWon += amount;
          update.betsWon += 1;
          
          // Add coins back to user's balance if they won
          update.coinsToAdd = (update.coinsToAdd || 0) + (amount * 2);
        }
      }
    }
    
    // Apply leaderboard updates
    for (const [, update] of leaderboardUpdates) {
      const updateData = {
        coinsWon: admin.firestore.FieldValue.increment(update.coinsWon),
        betsWon: admin.firestore.FieldValue.increment(update.betsWon)
      };
      
      if (update.coinsToAdd) {
        updateData.coinsRemaining = admin.firestore.FieldValue.increment(update.coinsToAdd);
      }
      
      batch.update(update.ref, updateData);
    }
    
    await batch.commit();
    
    functions.logger.info(`Successfully processed bet results for game ${gameId}`);
    return null;
  });

/**
 * Finalize tournament and distribute payouts
 * Runs every Sunday at 12:00 AM
 */
export const finalizeTournament = functions.pubsub
  .schedule("0 0 * * 0")
  .timeZone("America/New_York")
  .onRun(async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    // Find tournament that ended yesterday
    const tournamentQuery = await db.collection("tournaments")
      .where("status", "==", "active")
      .where("endDate", "<=", admin.firestore.Timestamp.fromDate(yesterday))
      .limit(1)
      .get();
    
    if (tournamentQuery.empty) {
      functions.logger.info("No tournaments to finalize");
      return null;
    }
    
    const tournamentDoc = tournamentQuery.docs[0];
    const tournament = tournamentDoc.data();
    const tournamentId = tournamentDoc.id;
    
    functions.logger.info(`Finalizing tournament ${tournamentId}`);
    
    // Get all leaderboard entries for this tournament
    const leaderboardQuery = await db.collection("leaderboard")
      .where("tournamentId", "==", tournamentId)
      .get();
    
    // Sort entries by performance (coins remaining + coins won)
    const entries = leaderboardQuery.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        userId: data.userId,
        coinsRemaining: data.coinsRemaining || 0,
        coinsWon: data.coinsWon || 0,
        totalCoins: (data.coinsRemaining || 0) + (data.coinsWon || 0),
        ref: doc.ref
      };
    });
    
    entries.sort((a, b) => b.totalCoins - a.totalCoins);
    
    // Assign ranks
    const batch = db.batch();
    const payouts = [];
    
    // Handle tied ranks
    let currentRank = 1;
    let currentScore = -1;
    let sameRankCount = 0;
    
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      
      // If score is different from previous, assign new rank
      if (entry.totalCoins !== currentScore) {
        currentRank = i + 1;
        currentScore = entry.totalCoins;
        sameRankCount = 0;
      } else {
        sameRankCount++;
      }
      
      // Update leaderboard entry with rank
      batch.update(entry.ref, { rank: currentRank });
      
      // Check if this rank gets a payout
      const payoutTiers = tournament.payoutStructure || [];
      
      for (const tier of payoutTiers) {
        if (tier.rank === currentRank) {
          // This entry gets a payout
          let amount = tournament.totalPrizePool * tier.percentOfPool;
          
          // If there are ties, share the prize pool for those ranks
          if (sameRankCount > 0) {
            // Find all prize money for the tied ranks
            let totalTiedMoney = tier.percentOfPool;
            const nextTierIndex = payoutTiers.findIndex(t => t.rank === currentRank + 1);
            
            if (nextTierIndex !== -1) {
              totalTiedMoney += tier.percentOfPool;
            }
            
            // Divide equally
            amount = (tournament.totalPrizePool * totalTiedMoney) / (sameRankCount + 1);
          }
          
          payouts.push({
            userId: entry.userId,
            amount: amount,
            rank: currentRank
          });
          
          break;
        }
      }
    }
    
    // Create payout records
    for (const payout of payouts) {
      const payoutRef = db.collection("payouts").doc();
      batch.set(payoutRef, {
        userId: payout.userId,
        tournamentId: tournamentId,
        amount: payout.amount,
        rank: payout.rank,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Update user tournament stats
      const userRef = db.collection("users").doc(payout.userId);
      batch.update(userRef, {
        "tournamentStats.totalWinnings": admin.firestore.FieldValue.increment(payout.amount),
        "tournamentStats.bestFinish": admin.firestore.FieldValue.increment(0) // Will be set in a second operation
      });
      
      // Get user's current best finish
      const userDoc = await userRef.get();
      const userData = userDoc.data();
      if (userData) {
        const currentBestFinish = userData.tournamentStats?.bestFinish || 999;
        if (payout.rank < currentBestFinish) {
          batch.update(userRef, {
            "tournamentStats.bestFinish": payout.rank
          });
        }
      }
    }
    
    // Update tournament status
  // Update tournament status
    batch.update(tournamentDoc.ref, {
      status: "completed",
      finalizedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    await batch.commit();
    
    functions.logger.info(`Finalized tournament ${tournamentId} with ${payouts.length} winners`);
    return null;
  });

/**
 * Reset weekly coins
 * Runs every Sunday at 12:05 AM
 */
export const resetWeeklyCoins = functions.pubsub
  .schedule("5 0 * * 0")
  .timeZone("America/New_York")
  .onRun(async () => {
    // Get users with active subscriptions
    const activeUsersQuery = await db.collection("users")
      .where("subscriptionStatus", "==", "active")
      .get();
    
    if (activeUsersQuery.empty) {
      functions.logger.info("No active users to reset coins for");
      return null;
    }
    
    const batch = db.batch();
    const nextWeekReset = new Date();
    nextWeekReset.setDate(nextWeekReset.getDate() + 7);
    
    // Reset coins for each user
    for (const userDoc of activeUsersQuery.docs) {
      batch.update(userDoc.ref, {
        weeklyCoins: 1000,
        weeklyCoinsReset: admin.firestore.Timestamp.fromDate(nextWeekReset),
        "tournamentStats.tournamentsEntered": admin.firestore.FieldValue.increment(1)
      });
      
      // Find current tournament
      const tournamentQuery = await db.collection("tournaments")
        .where("status", "==", "active")
        .limit(1)
        .get();
      
      if (!tournamentQuery.empty) {
        const tournamentId = tournamentQuery.docs[0].id;
        const userId = userDoc.id;
        
        // Check if user already has a leaderboard entry
        const leaderboardQuery = await db.collection("leaderboard")
          .where("tournamentId", "==", tournamentId)
          .where("userId", "==", userId)
          .limit(1)
          .get();
        
        if (leaderboardQuery.empty) {
          // Create new leaderboard entry
          const username = userDoc.data().email?.split('@')[0] || "User";
          
          const leaderboardRef = db.collection("leaderboard").doc();
          batch.set(leaderboardRef, {
            userId: userId,
            tournamentId: tournamentId,
            username: username,
            rank: 0,
            coinsRemaining: 1000,
            coinsBet: 0,
            coinsWon: 0,
            betsPlaced: 0,
            betsWon: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
          
          // Update user's current tournament
          batch.update(userDoc.ref, {
            currentTournamentId: tournamentId
          });
          
          // Update tournament participant count
          const tournamentRef = db.collection("tournaments").doc(tournamentId);
          batch.update(tournamentRef, {
            participantCount: admin.firestore.FieldValue.increment(1)
          });
        } else {
          // Reset existing leaderboard entry
          batch.update(leaderboardQuery.docs[0].ref, {
            coinsRemaining: 1000,
            coinsBet: 0,
            coinsWon: 0,
            betsPlaced: 0,
            betsWon: 0
          });
        }
      }
    }
    
    await batch.commit();
    
    functions.logger.info(`Reset weekly coins for ${activeUsersQuery.size} users`);
    return null;
  });

/**
 * Process login streak and daily coin bonus
 */
export const processLoginBonus = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;
    
    // Check if this is a login timestamp update
    if (!after.lastLoginDate || 
        (before.lastLoginDate && 
         after.lastLoginDate.toMillis() === before.lastLoginDate.toMillis())) {
      return null;
    }
    
    const lastLoginDate = before.lastLoginDate ? new Date(before.lastLoginDate.toMillis()) : null;
    const currentLoginDate = new Date(after.lastLoginDate.toMillis());
    
    // Check if this is a new day login
    if (lastLoginDate && 
        lastLoginDate.getDate() === currentLoginDate.getDate() &&
        lastLoginDate.getMonth() === currentLoginDate.getMonth() &&
        lastLoginDate.getFullYear() === currentLoginDate.getFullYear()) {
      return null;
    }
    
    // Calculate if streak continues
    let newStreak = 1;
    if (lastLoginDate) {
      const yesterdayDate = new Date(currentLoginDate);
      yesterdayDate.setDate(yesterdayDate.getDate() - 1);
      
      if (lastLoginDate.getDate() === yesterdayDate.getDate() &&
          lastLoginDate.getMonth() === yesterdayDate.getMonth() &&
          lastLoginDate.getFullYear() === yesterdayDate.getFullYear()) {
        // Consecutive day login
        newStreak = (after.loginStreak || 0) + 1;
      } else {
        // Streak broken
        newStreak = 1;
      }
    }
    
    // Calculate bonus amount based on streak
    let bonusAmount = 0;
    if (newStreak >= 7) {
      bonusAmount = 50; // Week-long streak
    } else if (newStreak >= 3) {
      bonusAmount = 20; // 3+ day streak
    } else {
      bonusAmount = 10; // Regular daily bonus
    }
    
    // Only award bonus if user is in an active tournament
    if (!after.currentTournamentId) {
      return null;
    }
    
    // Find user's leaderboard entry
    const leaderboardQuery = await db.collection("leaderboard")
      .where("tournamentId", "==", after.currentTournamentId)
      .where("userId", "==", userId)
      .limit(1)
      .get();
    
    if (leaderboardQuery.empty) {
      return null;
    }
    
    // Update user data and leaderboard
    const batch = db.batch();
    
    // Update streak
    batch.update(change.after.ref, {
      loginStreak: newStreak
    });
    
    // Add bonus coins
    const leaderboardRef = leaderboardQuery.docs[0].ref;
    batch.update(leaderboardRef, {
      coinsRemaining: admin.firestore.FieldValue.increment(bonusAmount)
    });
    
    // Create login bonus record
    const bonusRef = db.collection("loginBonuses").doc();
    batch.set(bonusRef, {
      userId: userId,
      amount: bonusAmount,
      streak: newStreak,
      tournamentId: after.currentTournamentId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    await batch.commit();
    
    functions.logger.info(`Processed login bonus of ${bonusAmount} coins for user ${userId} (streak: ${newStreak})`);
    return null;
  });