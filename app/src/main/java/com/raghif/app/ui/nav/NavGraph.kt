package com.raghif.app.ui.nav

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.raghif.app.ui.screens.*

@Composable
fun AppNavGraph(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = "login"
    ) {
        composable("login") {
            LoginScreen(
                onNavigateToStoreList = {
                    navController.navigate("storeList")
                },
                onNavigateToOwnerDashboard = {
                    navController.navigate("ownerDashboard")
                }
            )
        }
        composable("storeList") {
            StoreListScreen(
                onNavigateToPurchase = { storeId ->
                    navController.navigate("purchase/$storeId")
                },
                onLogout = {
                    navController.navigate("login") { popUpTo("login") { inclusive = true } }
                }
            )
        }
        composable(
            route = "purchase/{storeId}",
            arguments = listOf(navArgument("storeId") { type = NavType.StringType })
        ) { backStackEntry ->
            val storeId = backStackEntry.arguments?.getString("storeId") ?: ""
            PurchaseScreen(
                storeId = storeId,
                onNavigateToConfirmation = { purchaseId ->
                    navController.navigate("confirmation/$purchaseId")
                },
                onBack = {
                    navController.popBackStack()
                }
            )
        }
        composable(
            route = "confirmation/{purchaseId}",
            arguments = listOf(navArgument("purchaseId") { type = NavType.StringType })
        ) { backStackEntry ->
            val purchaseId = backStackEntry.arguments?.getString("purchaseId") ?: ""
            ConfirmationScreen(
                purchaseId = purchaseId,
                onNavigateToStoreList = {
                    navController.navigate("storeList") {
                        popUpTo("storeList") { inclusive = true }
                    }
                }
            )
        }
        composable("ownerDashboard") {
            OwnerDashboardScreen(
                onNavigateToQueue = {
                    navController.navigate("ownerQueue")
                },
                onLogout = {
                    navController.navigate("login") { popUpTo("login") { inclusive = true } }
                }
            )
        }
        composable("ownerQueue") {
            OwnerQueueScreen(
                onBack = {
                    navController.popBackStack()
                },
                onLogout = {
                    navController.navigate("login") { popUpTo("login") { inclusive = true } }
                }
            )
        }
    }
}
