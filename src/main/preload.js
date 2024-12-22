console.log('Preload script loaded'); // Debug log to confirm loading
import { registerTestApi } from './contextBridges/testAPI.js';

// ADD ANY CONTEXT BRIDGE API S HERE

try {
  registerTestApi();
  console.log('Test API registered successfully');
} catch (error) {
  console.error('Error registering Test API:', error);
}