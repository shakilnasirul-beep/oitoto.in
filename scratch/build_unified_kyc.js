const fs = require('fs');

const modalHtml = `
    <!-- MODAL: PARTNER & VEHICLE UNIFIED KYC VERIFICATION HUB -->
    <div class="modal fade" id="driverKYCModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-xl">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px; overflow: hidden;">
                <div class="modal-header bg-dark text-white py-3 px-4 d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center gap-2.5">
                        <span class="badge bg-primary p-2 rounded-circle"><i class="bi bi-shield-check text-white fs-5"></i></span>
                        <div>
                            <h5 class="modal-title fw-bold mb-0 text-white" id="driverKYCModalTitle">Partner & Vehicle Unified KYC Verification Hub</h5>
                            <small class="text-white-50" style="font-size: 0.72rem;">Mobile App OTP Onboarding &bull; Driver Identity &bull; Vehicle RTO Papers &bull; 3-Angle Vehicle Photos Audit</small>
                        </div>
                    </div>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body p-4" id="driverKYCModalBody" style="background-color: #F8FAFC; max-height: 85vh; overflow-y: auto;">
                    <!-- Dynamically populated by openDriverKYCModal -->
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL: VEHICLE KYC (ALIASED TO UNIFIED HUB FOR BACKWARD COMPATIBILITY) -->
    <div class="modal fade" id="vehicleKYCModal" tabindex="-1" aria-hidden="true" style="display:none;">
        <div class="modal-dialog modal-dialog-centered modal-xl">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px; overflow: hidden;">
                <div class="modal-body p-4" id="vehicleKYCModalBody">
                    <!-- Forwarded to driverKYCModal -->
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL: VEHICLE & DOCUMENT HD PHOTO LIGHTBOX -->
    <div class="modal fade" id="vehiclePhotoLightboxModal" tabindex="-1" aria-hidden="true" style="z-index: 1060;">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content border-0 shadow-2xl" style="border-radius: 16px; overflow: hidden; background: #0F172A; color: #FFFFFF;">
                <div class="modal-header border-0 py-3 px-4 d-flex justify-content-between align-items-center" style="background: #1E293B;">
                    <div class="d-flex align-items-center gap-2">
                        <i class="bi bi-camera-fill text-warning fs-5"></i>
                        <h6 class="modal-title fw-bold text-white mb-0" id="photoLightboxTitle">Inspection Photo Preview</h6>
                    </div>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body p-4 text-center" id="photoLightboxBody">
                    <!-- Photo container populated dynamically -->
                </div>
                <div class="modal-footer border-0 py-2.5 px-4 justify-content-between" style="background: #1E293B;">
                    <div class="small text-white-50" id="photoLightboxSubtitle">Verified Plate & Identity Inspection</div>
                    <button type="button" class="btn btn-sm btn-outline-light" data-bs-dismiss="modal">Close Preview</button>
                </div>
            </div>
        </div>
    </div>
`;

console.log('Modal HTML generated, length:', modalHtml.length);
