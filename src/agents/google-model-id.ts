/**
 * Google/Gemini model id normalization (shared by model-selection and models-config).
 * Kept in a leaf module to avoid importing the full models-config graph from model-selection.
 */

export function normalizeGoogleModelId(id: string): string {
  if (id === "gemini-3-pro") {
    return "gemini-3-pro-preview";
  }
  if (id === "gemini-3-flash") {
    return "gemini-3-flash-preview";
  }
  return id;
}
