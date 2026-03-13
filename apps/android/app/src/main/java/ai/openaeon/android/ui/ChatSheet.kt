package ai.openaeon.android.ui

import androidx.compose.runtime.Composable
import ai.openaeon.android.MainViewModel
import ai.openaeon.android.ui.chat.ChatSheetContent

@Composable
fun ChatSheet(viewModel: MainViewModel) {
  ChatSheetContent(viewModel = viewModel)
}
