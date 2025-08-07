/**
 * Upload Manager - Usage Examples
 * 
 * This file demonstrates how to use the uploadManager library in different contexts
 * throughout the M3 Nexus application.
 * 
 * Author: Thúlio Silva
 */

import { createBudgetUploadManager, createRegularUploadManager } from '../../../../00_frontend/src/lib/uploadManager';

/**
 * Example 1: Basic Budget Upload (Component Budget Context)
 * Use this for component-specific budget uploads where files are staged temporarily
 */
export function useBudgetUploadExample() {
  const [uploadedFiles, setUploadedFiles] = useState([]);
  const uploadManagerRef = useRef(null);

  useEffect(() => {
    // Initialize budget upload manager with callbacks
    uploadManagerRef.current = createBudgetUploadManager({
      onProgress: (fileId, progress) => {
        console.log(`File ${fileId}: ${progress}%`);
        setUploadedFiles(prev => prev.map(file => 
          file.id === fileId ? { ...file, progress } : file
        ));
      },
      onStatusChange: (fileId, status) => {
        console.log(`File ${fileId}: ${status}`);
        setUploadedFiles(prev => prev.map(file => 
          file.id === fileId ? { ...file, status } : file
        ));
      },
      onSuccess: (fileId, result) => {
        console.log(`File ${fileId} uploaded successfully:`, result);
        setUploadedFiles(prev => prev.map(file => 
          file.id === fileId 
            ? { 
                ...file, 
                status: 'success',
                onedrive_item_id: result.onedrive_item_id,
                download_url: result.onedrive_download_url
              }
            : file
        ));
      },
      onError: (fileId, error) => {
        console.error(`File ${fileId} failed:`, error);
        setUploadedFiles(prev => prev.map(file => 
          file.id === fileId ? { ...file, status: 'error', error } : file
        ));
      }
    });

    return () => {
      // Cleanup if needed
      uploadManagerRef.current = null;
    };
  }, []);

  const handleUploadFiles = async (files, componentId) => {
    if (uploadManagerRef.current) {
      // Upload multiple files in parallel
      const results = await uploadManagerRef.current.uploadFiles(componentId, files, {
        orderId: 'optional-order-id'
      });
      console.log('Upload results:', results);
    }
  };

  const handleDownloadFile = async (oneDriveItemId, fileName) => {
    if (uploadManagerRef.current) {
      await uploadManagerRef.current.downloadFile(oneDriveItemId, fileName, true);
    }
  };

  const handleRemoveFile = async (oneDriveItemId, fileName) => {
    if (uploadManagerRef.current) {
      await uploadManagerRef.current.removeFile(oneDriveItemId, fileName, true);
      // Update local state
      setUploadedFiles(prev => prev.filter(file => file.onedrive_item_id !== oneDriveItemId));
    }
  };

  return {
    uploadedFiles,
    handleUploadFiles,
    handleDownloadFile,
    handleRemoveFile
  };
}

/**
 * Example 2: Regular Upload (Permanent Storage Context)
 * Use this for permanent file storage in orders, components, etc.
 */
export function useRegularUploadExample() {
  const [uploadedFiles, setUploadedFiles] = useState([]);
  const uploadManagerRef = useRef(null);

  useEffect(() => {
    // Initialize regular upload manager
    uploadManagerRef.current = createRegularUploadManager({
      onProgress: (fileId, progress) => {
        setUploadedFiles(prev => prev.map(file => 
          file.id === fileId ? { ...file, progress } : file
        ));
      },
      onStatusChange: (fileId, status) => {
        setUploadedFiles(prev => prev.map(file => 
          file.id === fileId ? { ...file, status } : file
        ));
      },
      onSuccess: (fileId, result) => {
        setUploadedFiles(prev => prev.map(file => 
          file.id === fileId 
            ? { 
                ...file, 
                status: 'success',
                onedrive_item_id: result.onedrive_item_id,
                permanent_file_id: result.fileId // For permanent files
              }
            : file
        ));
      },
      onError: (fileId, error) => {
        setUploadedFiles(prev => prev.map(file => 
          file.id === fileId ? { ...file, status: 'error', error } : file
        ));
      }
    });

    return () => {
      uploadManagerRef.current = null;
    };
  }, []);

  const handleUploadFiles = async (files, componentId) => {
    if (uploadManagerRef.current) {
      const results = await uploadManagerRef.current.uploadFiles(componentId, files, {
        orderId: 'required-order-id',
        permanent: true // Flag for permanent storage
      });
      console.log('Regular upload results:', results);
    }
  };

  return {
    uploadedFiles,
    handleUploadFiles
  };
}

/**
 * Example 3: Single File Upload with Custom Progress Handling
 * Use this when you need fine-grained control over individual file uploads
 */
export async function uploadSingleFileExample(file, componentId, options = {}) {
  const uploadManager = createBudgetUploadManager({
    onProgress: (fileId, progress) => {
      console.log(`Uploading ${file.name}: ${progress}%`);
      // Custom progress handling logic here
      if (options.onProgress) {
        options.onProgress(progress);
      }
    },
    onStatusChange: (fileId, status) => {
      console.log(`File status changed: ${status}`);
      if (options.onStatusChange) {
        options.onStatusChange(status);
      }
    }
  });

  try {
    const result = await uploadManager.uploadSingleFile(file, componentId, {
      fileId: options.customFileId || undefined,
      budgetCategory: options.budgetCategory || null,
      orderId: options.orderId
    });

    console.log('Single file upload result:', result);
    return result;
  } catch (error) {
    console.error('Single file upload failed:', error);
    throw error;
  }
}

/**
 * Example 4: File Validation for Budget Uploads
 * Use this to validate files before uploading in budget contexts
 */
export function validateBudgetFilesExample(files, requireExcel = true) {
  const uploadManager = createBudgetUploadManager();
  
  const validation = uploadManager.validateBudgetFiles(files, requireExcel);
  
  if (!validation.isValid) {
    console.warn('File validation failed:', validation.errors);
    // Show validation errors to user
    validation.errors.forEach(error => {
      console.error('Validation Error:', error);
    });
    return false;
  }

  console.log('File validation passed:', validation.counts);
  return true;
}

/**
 * Example 5: Bulk File Operations
 * Use this for bulk download or removal operations
 */
export class BulkFileOperationsExample {
  constructor(mode = 'budget') {
    this.uploadManager = mode === 'budget' 
      ? createBudgetUploadManager()
      : createRegularUploadManager();
  }

  async downloadMultipleFiles(files) {
    const downloadPromises = files.map(file => 
      this.uploadManager.downloadFile(
        file.onedrive_item_id,
        file.name,
        file.isStaged || true
      )
    );

    try {
      await Promise.allSettled(downloadPromises);
      console.log('Bulk download completed');
    } catch (error) {
      console.error('Bulk download failed:', error);
    }
  }

  async removeMultipleFiles(files) {
    const removalPromises = files.map(file => 
      this.uploadManager.removeFile(
        file.onedrive_item_id,
        file.name,
        file.isStaged || true
      )
    );

    try {
      await Promise.allSettled(removalPromises);
      console.log('Bulk removal completed');
    } catch (error) {
      console.error('Bulk removal failed:', error);
    }
  }
}

/**
 * Example 6: Integration with React Components
 * Complete example of how to integrate uploadManager with a React component
 */
export const UploadManagerReactExample = () => {
  const [files, setFiles] = useState([]);
  const [isUploading, setIsUploading] = useState(false);
  const uploadManagerRef = useRef(null);

  useEffect(() => {
    uploadManagerRef.current = createBudgetUploadManager({
      onProgress: (fileId, progress) => {
        setFiles(prev => prev.map(f => 
          f.id === fileId ? { ...f, progress } : f
        ));
      },
      onStatusChange: (fileId, status) => {
        setFiles(prev => prev.map(f => 
          f.id === fileId ? { ...f, status } : f
        ));
        
        // Check if all uploads are complete
        setFiles(current => {
          const uploading = current.some(f => 
            f.status === 'queueing' || f.status === 'carregando' || f.status === 'finalizando'
          );
          setIsUploading(uploading);
          return current;
        });
      },
      onSuccess: (fileId, result) => {
        setFiles(prev => prev.map(f => 
          f.id === fileId 
            ? { ...f, status: 'success', result }
            : f
        ));
      },
      onError: (fileId, error) => {
        setFiles(prev => prev.map(f => 
          f.id === fileId ? { ...f, status: 'error', error } : f
        ));
      }
    });

    return () => {
      uploadManagerRef.current = null;
    };
  }, []);

  const handleFileSelect = async (selectedFiles) => {
    // Create file entries with initial state
    const newFiles = selectedFiles.map(file => ({
      id: `upload_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name: file.name,
      file: file,
      status: 'queueing',
      progress: 0
    }));

    setFiles(prev => [...prev, ...newFiles]);
    setIsUploading(true);

    // Start uploads
    if (uploadManagerRef.current) {
      await uploadManagerRef.current.uploadFiles('component-id', selectedFiles);
    }
  };

  const handleFileRemove = async (fileId) => {
    const file = files.find(f => f.id === fileId);
    if (file?.result?.onedrive_item_id && uploadManagerRef.current) {
      await uploadManagerRef.current.removeFile(
        file.result.onedrive_item_id,
        file.name,
        true
      );
    }
    setFiles(prev => prev.filter(f => f.id !== fileId));
  };

  const handleFileDownload = async (fileId) => {
    const file = files.find(f => f.id === fileId);
    if (file?.result?.onedrive_item_id && uploadManagerRef.current) {
      await uploadManagerRef.current.downloadFile(
        file.result.onedrive_item_id,
        file.name,
        true
      );
    }
  };

  return (
    <div>
      <input
        type="file"
        multiple
        onChange={(e) => handleFileSelect(Array.from(e.target.files))}
      />
      
      {isUploading && <div>Uploading files...</div>}
      
      <div>
        {files.map(file => (
          <div key={file.id}>
            <span>{file.name}</span>
            <span>{file.status}</span>
            {file.progress > 0 && <span>{file.progress}%</span>}
            {file.status === 'success' && (
              <button onClick={() => handleFileDownload(file.id)}>
                Download
              </button>
            )}
            <button onClick={() => handleFileRemove(file.id)}>
              Remove
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

/**
 * Example 7: Error Handling Patterns
 * Best practices for handling upload errors
 */
export function handleUploadErrorsExample() {
  const uploadManager = createBudgetUploadManager({
    onError: (fileId, error) => {
      console.error(`Upload error for ${fileId}:`, error);
      
      // Categorize errors
      if (error.includes('OneDrive')) {
        // OneDrive-specific error
        toast.error('Erro de conexão com OneDrive. Tente novamente.');
      } else if (error.includes('sessão')) {
        // Session creation error
        toast.error('Erro ao criar sessão de upload. Verifique sua conexão.');
      } else if (error.includes('rede')) {
        // Network error
        toast.error('Erro de rede. Verifique sua conexão de internet.');
      } else {
        // Generic error
        toast.error(`Erro no upload: ${error}`);
      }
    }
  });

  return uploadManager;
}

/**
 * Example 8: Configuration Options
 * How to customize uploadManager behavior
 */
export function createCustomUploadManager() {
  return createBudgetUploadManager({
    // Custom progress callback with throttling
    onProgress: throttle((fileId, progress) => {
      console.log(`${fileId}: ${progress}%`);
    }, 100), // Update progress every 100ms max
    
    // Status change with logging
    onStatusChange: (fileId, status) => {
      const timestamp = new Date().toISOString();
      console.log(`[${timestamp}] ${fileId}: ${status}`);
    },
    
    // Success with analytics tracking
    onSuccess: (fileId, result) => {
      console.log('Upload successful:', result);
      // Track analytics
      if (typeof gtag !== 'undefined') {
        gtag('event', 'file_upload_success', {
          file_type: result.budgetCategory || 'unknown',
          file_size: result.fileSize || 0
        });
      }
    },
    
    // Error with detailed logging
    onError: (fileId, error) => {
      console.error('Upload failed:', { fileId, error, timestamp: new Date() });
      // Report to error tracking service
      if (typeof Sentry !== 'undefined') {
        Sentry.captureException(new Error(`Upload failed: ${error}`));
      }
    }
  });
}

// Utility function for throttling (you'd import this from lodash or implement it)
function throttle(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}