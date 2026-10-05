/**
 * TAMS (Travel Agency Management System) - Central Frontend API Client
 * Connects all website frontend templates to Django REST APIs and PostgreSQL.
 */
(function (global) {
    "use strict";

    // Auto-detect backend API host (defaults to current origin or localhost:8000)
    const isLiveServer = window.location.port !== "8000" && window.location.hostname !== "";
    const defaultHost = isLiveServer ? `http://${window.location.hostname || "127.0.0.1"}:8000` : "";
    const BASE_URL = (global.TAMS_API_BASE || defaultHost) + "/api/v1";

    // Session / Auth helpers
    function getToken() {
        return sessionStorage.getItem("tamsToken") || localStorage.getItem("tamsToken") || "";
    }

    function setToken(token) {
        if (token) {
            sessionStorage.setItem("tamsToken", token);
            localStorage.setItem("tamsToken", token);
        } else {
            sessionStorage.removeItem("tamsToken");
            localStorage.removeItem("tamsToken");
        }
    }

    async function request(endpoint, options = {}) {
        const url = endpoint.startsWith("http") ? endpoint : `${BASE_URL}${endpoint}`;
        const headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            ...(options.headers || {})
        };

        const token = getToken();
        if (token) {
            headers["Authorization"] = `Token ${token}`;
        }

        const config = {
            ...options,
            headers
        };

        try {
            const res = await fetch(url, config);

            // Handle non-JSON responses (e.g. file downloads)
            const contentType = res.headers.get("content-type") || "";
            if (contentType.includes("text/csv") || contentType.includes("application/octet-stream")) {
                if (!res.ok) throw new Error("File export failed.");
                return res.blob();
            }

            let data;
            try {
                data = await res.json();
            } catch (jsonErr) {
                data = { detail: res.statusText };
            }

            if (!res.ok) {
                // Parse DRF validation errors into clean user message
                let errorMsg = "Something went wrong.";
                if (data.detail) {
                    errorMsg = data.detail;
                } else if (data.error) {
                    errorMsg = data.error;
                } else if (typeof data === "object") {
                    const messages = [];
                    for (const [k, v] of Object.entries(data)) {
                        const strV = Array.isArray(v) ? v.join(" ") : String(v);
                        messages.push(`${k === 'non_field_errors' ? '' : k + ': '}${strV}`);
                    }
                    if (messages.length) errorMsg = messages.join(" | ");
                }
                const err = new Error(errorMsg);
                err.status = res.status;
                err.data = data;
                throw err;
            }

            return data;
        } catch (netErr) {
            console.error(`[TAMS API Error] ${url}:`, netErr);
            throw netErr;
        }
    }

    const TAMS = {
        BASE_URL,
        getToken,
        setToken,

        // Authentication
        auth: {
            async register(data) {
                const res = await request("/auth/register/", {
                    method: "POST",
                    body: JSON.stringify(data)
                });
                if (res.token) setToken(res.token);
                return res;
            },
            async login(email, password, role) {
                const res = await request("/auth/login/", {
                    method: "POST",
                    body: JSON.stringify({ email, password, role })
                });
                if (res.token) setToken(res.token);
                if (res.user) {
                    sessionStorage.setItem("tamsRole", res.role);
                    sessionStorage.setItem("userRole", res.role);
                    sessionStorage.setItem("tamsEmail", res.user.email);
                    sessionStorage.setItem("tamsName", res.user.full_name || res.user.username);
                    sessionStorage.setItem("customerName", res.user.full_name || res.user.username);
                }
                return res;
            },
            async logout() {
                try {
                    await request("/auth/logout/", { method: "POST" });
                } catch (e) {}
                setToken("");
                [
                    "customerName", "userRole", "tamsRole", "tamsEmail",
                    "tamsName", "tamsBookings", "tamsInvoices", "tamsDrivers"
                ].forEach(k => sessionStorage.removeItem(k));
            },
            async me() {
                return request("/auth/me/");
            },
            async updateProfile(data) {
                return request("/auth/me/", {
                    method: "PATCH",
                    body: JSON.stringify(data)
                });
            }
        },

        // Vehicles
        vehicles: {
            async list(params = {}) {
                const q = new URLSearchParams(params).toString();
                return request(`/vehicles/${q ? '?' + q : ''}`);
            },
            async get(id) {
                return request(`/vehicles/${id}/`);
            },
            async create(data) {
                return request("/vehicles/", {
                    method: "POST",
                    body: JSON.stringify(data)
                });
            },
            async update(id, data) {
                return request(`/vehicles/${id}/`, {
                    method: "PATCH",
                    body: JSON.stringify(data)
                });
            },
            async delete(id) {
                return request(`/vehicles/${id}/`, { method: "DELETE" });
            },
            async checkAvailability(id, pickupDate, returnDate) {
                const q = new URLSearchParams({ pickup_date: pickupDate, return_date: returnDate }).toString();
                return request(`/vehicles/${id}/check_availability/?${q}`);
            }
        },

        // Drivers
        drivers: {
            async list(params = {}) {
                const q = new URLSearchParams(params).toString();
                return request(`/drivers/${q ? '?' + q : ''}`);
            },
            async get(id) {
                return request(`/drivers/${id}/`);
            },
            async create(data) {
                return request("/drivers/", {
                    method: "POST",
                    body: JSON.stringify(data)
                });
            },
            async update(id, data) {
                return request(`/drivers/${id}/`, {
                    method: "PATCH",
                    body: JSON.stringify(data)
                });
            },
            async delete(id) {
                return request(`/drivers/${id}/`, { method: "DELETE" });
            },
            async myProfile() {
                return request("/drivers/my_profile/");
            },
            async updateMyProfile(data) {
                return request("/drivers/my_profile/", {
                    method: "PATCH",
                    body: JSON.stringify(data)
                });
            },
            async updateStatus(status) {
                return request("/drivers/update_status/", {
                    method: "POST",
                    body: JSON.stringify({ status })
                });
            }
        },

        // Customers
        customers: {
            async list(params = {}) {
                const q = new URLSearchParams(params).toString();
                return request(`/customers/${q ? '?' + q : ''}`);
            },
            async create(data) {
                return request("/customers/", {
                    method: "POST",
                    body: JSON.stringify(data)
                });
            },
            async update(id, data) {
                return request(`/customers/${id}/`, {
                    method: "PATCH",
                    body: JSON.stringify(data)
                });
            }
        },

        // Bookings
        bookings: {
            async list(params = {}) {
                const q = new URLSearchParams(params).toString();
                return request(`/bookings/${q ? '?' + q : ''}`);
            },
            async get(id) {
                return request(`/bookings/${id}/`);
            },
            async create(data) {
                return request("/bookings/", {
                    method: "POST",
                    body: JSON.stringify(data)
                });
            },
            async update(id, data) {
                return request(`/bookings/${id}/`, {
                    method: "PATCH",
                    body: JSON.stringify(data)
                });
            },
            async cancel(id) {
                return request(`/bookings/${id}/cancel/`, { method: "POST" });
            },
            async accept(id, data = {}) {
                return request(`/bookings/${id}/accept/`, {
                    method: "POST",
                    body: JSON.stringify(data)
                });
            },
            async myBookings(customerName = "") {
                const q = customerName ? `?customer_name=${encodeURIComponent(customerName)}` : "";
                return request(`/bookings/my_bookings/${q}`);
            }
        },

        // Duty Slips
        dutySlips: {
            async list(params = {}) {
                const q = new URLSearchParams(params).toString();
                return request(`/duty-slips/${q ? '?' + q : ''}`);
            },
            async get(id) {
                return request(`/duty-slips/${id}/`);
            },
            async create(data) {
                return request("/duty-slips/", {
                    method: "POST",
                    body: JSON.stringify(data)
                });
            },
            async update(id, data) {
                return request(`/duty-slips/${id}/`, {
                    method: "PATCH",
                    body: JSON.stringify(data)
                });
            },
            async startTrip(id, startOdometer) {
                return request(`/duty-slips/${id}/start_trip/`, {
                    method: "POST",
                    body: JSON.stringify({ start_odometer: startOdometer })
                });
            },
            async completeTrip(id, endOdometer) {
                return request(`/duty-slips/${id}/complete_trip/`, {
                    method: "POST",
                    body: JSON.stringify({ end_odometer: endOdometer })
                });
            },
            async mySlips(driverName = "") {
                const q = driverName ? `?driver_name=${encodeURIComponent(driverName)}` : "";
                return request(`/duty-slips/my_slips/${q}`);
            }
        },

        // Invoices / Billing
        invoices: {
            async list(params = {}) {
                const q = new URLSearchParams(params).toString();
                return request(`/invoices/${q ? '?' + q : ''}`);
            },
            async get(id) {
                return request(`/invoices/${id}/`);
            },
            async create(data) {
                return request("/invoices/", {
                    method: "POST",
                    body: JSON.stringify(data)
                });
            },
            async markPaid(id, method = "Cash") {
                return request(`/invoices/${id}/mark_paid/`, {
                    method: "POST",
                    body: JSON.stringify({ payment_method: method })
                });
            },
            async myInvoices(customerName = "") {
                const q = customerName ? `?customer_name=${encodeURIComponent(customerName)}` : "";
                return request(`/invoices/my_invoices/${q}`);
            }
        },

        // Simulated Payments
        payments: {
            async initiate(invoiceId, method = "UPI") {
                return request("/payments/initiate/", {
                    method: "POST",
                    body: JSON.stringify({ invoice_id: invoiceId, payment_method: method })
                });
            },
            async confirm(transactionRef, paymentId = null) {
                return request("/payments/confirm/", {
                    method: "POST",
                    body: JSON.stringify({ transaction_ref: transactionRef, payment_id: paymentId })
                });
            },
            async cancel(transactionRef, paymentId = null) {
                return request("/payments/cancel/", {
                    method: "POST",
                    body: JSON.stringify({ transaction_ref: transactionRef, payment_id: paymentId })
                });
            }
        },

        // Maintenance
        maintenance: {
            async list(params = {}) {
                const q = new URLSearchParams(params).toString();
                return request(`/maintenance/${q ? '?' + q : ''}`);
            },
            async get(id) {
                return request(`/maintenance/${id}/`);
            },
            async create(data) {
                return request("/maintenance/", {
                    method: "POST",
                    body: JSON.stringify(data)
                });
            },
            async update(id, data) {
                return request(`/maintenance/${id}/`, {
                    method: "PATCH",
                    body: JSON.stringify(data)
                });
            },
            async startService(id) {
                return request(`/maintenance/${id}/start_service/`, { method: "POST" });
            },
            async completeService(id, actualCost) {
                return request(`/maintenance/${id}/complete_service/`, {
                    method: "POST",
                    body: JSON.stringify({ actual_cost: actualCost })
                });
            }
        },

        // Dashboard & Reports
        dashboard: {
            async getSummary() {
                return request("/dashboard/");
            }
        },
        reports: {
            async getAnalytics() {
                return request("/reports/analytics/");
            },
            getExportUrl(type = "bookings") {
                return `${BASE_URL}/reports/export-csv/?type=${type}`;
            }
        }
    };

    global.TAMS_API = TAMS;
})(window);
