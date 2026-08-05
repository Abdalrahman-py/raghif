package com.raghif.app.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface StoreDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(stores: List<StoreEntity>)

    @Query("SELECT * FROM StoreEntity ORDER BY name ASC")
    fun getAllStores(): Flow<List<StoreEntity>>

    @Query("SELECT * FROM StoreEntity WHERE id = :storeId")
    fun getStoreById(storeId: String): Flow<StoreEntity?>

    @Update
    suspend fun updateStore(store: StoreEntity)
}

@Dao
interface UserDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(users: List<UserEntity>)

    @Query("SELECT * FROM UserEntity WHERE phone = :phone AND pin = :pin LIMIT 1")
    suspend fun findByPhoneAndPin(phone: String, pin: String): UserEntity?

    @Query("SELECT * FROM UserEntity WHERE phone = :phone LIMIT 1")
    suspend fun findByPhone(phone: String): UserEntity?

    @Query("SELECT * FROM UserEntity WHERE id = :userId")
    fun getUserById(userId: String): Flow<UserEntity?>

    @Query("SELECT COUNT(*) FROM UserEntity")
    suspend fun countUsers(): Int

    @Update
    suspend fun updateUser(user: UserEntity)
}

@Dao
interface PurchaseDao {
    @Insert
    suspend fun insert(purchase: PurchaseEntity)

    @Query("SELECT * FROM PurchaseEntity WHERE storeId = :storeId AND purchaseDate = :date ORDER BY createdAt ASC")
    fun getQueueForStore(storeId: String, date: String): Flow<List<PurchaseEntity>>

    // one bag per ID per day, across ALL stores — this is the latest purchase for the
    // day regardless of which store it was bought from
    @Query("SELECT * FROM PurchaseEntity WHERE userId = :userId AND purchaseDate = :date ORDER BY createdAt DESC LIMIT 1")
    suspend fun findLatestForUserDate(userId: String, date: String): PurchaseEntity?

    @Query("SELECT * FROM PurchaseEntity WHERE id = :purchaseId")
    fun getPurchaseById(purchaseId: String): Flow<PurchaseEntity?>

    @Update
    suspend fun updatePurchase(purchase: PurchaseEntity)
}
