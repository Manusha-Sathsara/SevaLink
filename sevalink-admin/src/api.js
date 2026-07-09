const BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8080';

function authHeaders() {
  const token = localStorage.getItem('accessToken');
  return token ? { 'Authorization': `Bearer ${token}` } : {};
}

export async function login(identifier, password) {
  const res = await fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier, password })
  });
  if (!res.ok) {
    const body = await res.json().catch(()=>({}));
    throw new Error(body?.message || 'Login failed');
  }
  const wrapper = await res.json();
  const auth = wrapper.data;
  localStorage.setItem('accessToken', auth.accessToken);
  localStorage.setItem('refreshToken', auth.refreshToken);
  return auth.user;
}

export async function register(payload) {
  const res = await fetch(`${BASE}/api/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  const body = await res.json().catch(()=>({}));
  if (!res.ok) {
    throw new Error(body?.message || 'Registration failed');
  }
  const auth = body.data;
  localStorage.setItem('accessToken', auth.accessToken);
  localStorage.setItem('refreshToken', auth.refreshToken);
  return auth.user;
}

export async function forgotPassword(email) {
  const res = await fetch(`${BASE}/api/auth/forgot-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });
  const body = await res.json().catch(() => ({}));

  // Backend wraps the response in ApiResponse<T>
  if (!res.ok) {
    throw new Error(body?.message || 'Forgot password request failed');
  }

  if (body?.success === false) {
    throw new Error(body?.message || 'Forgot password request failed');
  }

  return body?.message || 'If your email exists, a reset link was sent.';
}

export async function resetPassword(token, newPassword) {
  const res = await fetch(`${BASE}/api/auth/reset-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token, newPassword })
  });
  const body = await res.json().catch(()=>({}));
  if (!res.ok) {
    throw new Error(body?.message || 'Reset password failed');
  }
  return body.message || 'Password reset successful';
}

export async function getCurrentUser() {
  const res = await fetch(`${BASE}/api/auth/me`, {
    headers: { ...authHeaders() }
  });
  if (!res.ok) throw new Error('Unauthorized');
  const wrapper = await res.json();
  return wrapper.data;
}

export async function getAdminDashboardStats() {
  const res = await fetch(`${BASE}/api/admin/dashboard`, {
    headers: { ...authHeaders() }
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body?.success === false) {
    throw new Error(body?.message || 'Failed to load dashboard stats');
  }
  return body.data || {
    totalUsers: 0,
    totalWorkers: 0,
    totalJobs: 0,
    onlineUsers: 0,
  };
}

export async function getAdminWorkers() {
  const res = await fetch(`${BASE}/api/workers/admin`, {
    headers: { ...authHeaders() }
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body?.success === false) {
    throw new Error(body?.message || 'Failed to load workers');
  }
  return body.data || [];
}

export async function getAllUsers() {
  const res = await fetch(`${BASE}/api/users`, {
    headers: { ...authHeaders() }
  });
  if (!res.ok) throw new Error('Failed to load users');
  return res.json();
}

export async function updateUser(userId, payload) {
  const res = await fetch(`${BASE}/api/users/${userId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', ...authHeaders() },
    body: JSON.stringify(payload)
  });
  if (!res.ok) {
    const body = await res.json().catch(()=>({}));
    throw new Error(body?.message || 'Failed to update user');
  }
  return res.json();
}

export async function blockUser(userId) {
  const res = await fetch(`${BASE}/api/users/${userId}`, {
    method: 'DELETE',
    headers: { ...authHeaders() }
  });
  const body = await res.json().catch(()=>({}));
  if (!res.ok || body?.success === false) {
    throw new Error(body?.message || 'Failed to block user');
  }
  return body;
}

export async function updateWorkerStatus(workerId, status) {
  const res = await fetch(`${BASE}/api/workers/${workerId}/status`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', ...authHeaders() },
    body: JSON.stringify({ status })
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body?.success === false) {
    throw new Error(body?.message || 'Failed to update worker status');
  }
  return body.data;
}

export async function getAllJobs() {
  const res = await fetch(`${BASE}/api/jobs/admin`, {
    headers: { ...authHeaders() }
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(body?.message || 'Failed to load jobs');
  }
  return body?.data ?? body ?? [];
}

export async function getAdminComplaints() {
  const res = await fetch(`${BASE}/api/admin/complaints`, {
    headers: { ...authHeaders() }
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body?.success === false) {
    throw new Error(body?.message || 'Failed to load complaints');
  }
  return body?.data ?? [];
}

export async function updateComplaintStatus(complaintId, status) {
  const res = await fetch(`${BASE}/api/admin/complaints/${complaintId}/status`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', ...authHeaders() },
    body: JSON.stringify({ status })
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body?.success === false) {
    throw new Error(body?.message || 'Failed to update complaint status');
  }
  return body?.data ?? body;
}

export async function updateJob(jobId, payload) {
  const res = await fetch(`${BASE}/api/jobs/${jobId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', ...authHeaders() },
    body: JSON.stringify(payload)
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(body?.message || 'Failed to update job');
  }
  return body?.data ?? body;
}

export async function deleteJob(jobId) {
  const res = await fetch(`${BASE}/api/jobs/${jobId}`, {
    method: 'DELETE',
    headers: { ...authHeaders() }
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(body?.message || 'Failed to delete job');
  }
  return body?.data ?? body;
}

export async function updateProfile(payload) {
  const res = await fetch(`${BASE}/api/auth/me`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', ...authHeaders() },
    body: JSON.stringify(payload)
  });
  if (!res.ok) {
    const body = await res.json().catch(()=>({}));
    throw new Error(body?.message || 'Update failed');
  }
  const wrapper = await res.json();
  return wrapper.data;
}

export function logout() {
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
}

export default { login, forgotPassword, resetPassword, getCurrentUser, getAdminDashboardStats, updateProfile, logout };
