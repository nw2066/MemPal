console.log('Preload script loaded'); // Debug log to confirm loading
import { registerApi } from './contextBridges/APIRegister.js';

// ADD ANY CONTEXT BRIDGE API S HERE

try {
  registerApi();
  console.log('Test API registered successfully');
} catch (error) {
  console.error('Error registering Test API:', error);
}