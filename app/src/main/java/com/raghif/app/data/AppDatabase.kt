package com.raghif.app.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [
        StoreEntity::class,
        UserEntity::class,
        PurchaseEntity::class
    ],
    version = 4,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun storeDao(): StoreDao
    abstract fun userDao(): UserDao
    abstract fun purchaseDao(): PurchaseDao

    companion object {
        // demo accounts + stores for the interview demo — hardcoded on purpose
        const val DEMO_BUYER_PHONE = "0599111111"
        const val DEMO_BUYER_PIN = "1234"
        const val DEMO_OWNER_PHONE = "0599222222"
        const val DEMO_OWNER_PIN = "1234"
        const val DEMO_STORE_ID = "store_1" // the one store the owner account manages

        @Volatile private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "bread_proto.db" // PROTOTYPE — wipe me
                )
                    .fallbackToDestructiveMigration()
                    .build()
                    .also { INSTANCE = it }
            }
        }

        // Called once from MainActivity, awaited with runBlocking before setContent —
        // NOT via RoomDatabase.Callback.onCreate, which fires the seed insert on a
        // fire-and-forget coroutine racing the very first screen's first query. That
        // race meant the first login attempt after a fresh install could fail because
        // the seed accounts weren't written yet. Awaiting this up front removes the race.
        suspend fun ensureSeeded(db: AppDatabase) {
            if (db.userDao().countUsers() > 0) return
            db.storeDao().insertAll(
                listOf(
                    StoreEntity("store_1", "Al-Rimal Bakery", isOpen = true, dailyBagLimit = 300, bagsRemaining = 300, batchSize = 20, allocationDate = todayDateString()),
                    StoreEntity("store_2", "Al-Shati Bakery", isOpen = true, dailyBagLimit = 300, bagsRemaining = 300, batchSize = 20, allocationDate = todayDateString()),
                    StoreEntity("store_3", "Nuseirat Bakery", isOpen = false, dailyBagLimit = 300, bagsRemaining = 0, batchSize = 20, allocationDate = todayDateString())
                )
            )
            db.userDao().insertAll(
                listOf(
                    UserEntity("user_buyer", DEMO_BUYER_PHONE, DEMO_BUYER_PIN, "buyer", balance = 50, personalId = "900111222", name = "أحمد ناصر"),
                    UserEntity("user_owner", DEMO_OWNER_PHONE, DEMO_OWNER_PIN, "owner", balance = 0, personalId = "900333444", name = "صاحب المخبز")
                )
            )
        }
    }
}
