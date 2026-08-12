import React, { useState, useEffect } from "react";
import * as api from "./api";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  LineChart,
  Line,
  CartesianGrid,
  Legend,
} from "recharts";
function App({ onLogout }) {
  const [adminName, setAdminName] = useState("");
  const [adminEmail, setAdminEmail] = useState("");
  const [complaintAlerts, setComplaintAlerts] = useState(true);
  const [workerRegistrationAlerts, setWorkerRegistrationAlerts] = useState(true);
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmNewPassword, setConfirmNewPassword] = useState("");
  const [profileImageUrl, setProfileImageUrl] = useState("");
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState(null);
  const [dashboardStats, setDashboardStats] = useState({
    totalUsers: 0,
    totalWorkers: 0,
    totalJobs: 0,
    onlineUsers: 0,
  });
  const [workers, setWorkers] = useState([]);
  const [enableUserRegistrations, setEnableUserRegistrations] = useState(() => {
    return localStorage.getItem("enableUserRegistrations") !== "false";
  });
  const [enableWorkerVerification, setEnableWorkerVerification] = useState(() => {
    return localStorage.getItem("enableWorkerVerification") !== "false";
  });
  const [selectedWorker, setSelectedWorker] = useState(null);
  const [showVerifyModal, setShowVerifyModal] = useState(false);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [nicNumber, setNicNumber] = useState("");
  const [verificationDocument, setVerificationDocument] = useState(null);
  const [policeReport, setPoliceReport] = useState(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [customRejectionReason, setCustomRejectionReason] = useState("");
  const [workerSearch, setWorkerSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState("All");
  const [workerLoading, setWorkerLoading] = useState(false);
  const [workerCategoryFilter, setWorkerCategoryFilter] = useState("All");
  const [workerStatusFilters, setWorkerStatusFilters] = useState([]);
  const [workerRatingFilters, setWorkerRatingFilters] = useState([]);
  const [workerJobFilters, setWorkerJobFilters] = useState([]);
  const loadAdminWorkers = async () => {
    setWorkerLoading(true);
    try {
      const data = await api.getAdminWorkers();
      setWorkers(data);
    } catch (error) {
      console.error("Failed to load admin workers", error);
      setWorkers([]);
    } finally {
      setWorkerLoading(false);
    }
  };
  useEffect(() => {
    // Fetch current user and dashboard stats when the admin loads the app
    api.getCurrentUser().then(user => {
      if (user) {
        setAdminName(user.fullName || "");
        setAdminEmail(user.email || "");
        setProfileImageUrl(user.profileImageUrl || "");
        setComplaintAlerts(user.complaintAlerts !== false);
        setWorkerRegistrationAlerts(user.workerRegistrationAlerts !== false);
      }
    }).catch(() => {});
    api.getAdminDashboardStats()
      .then(stats => setDashboardStats(stats))
      .catch(() => {
        setDashboardStats({
          totalUsers: 0,
          totalWorkers: 0,
          totalJobs: 0,
          onlineUsers: 0,
        });
      });
    loadAdminWorkers();
  }, []);
  const handleWorkerStatusChange = async (workerId, status) => {
    try {
      await api.updateWorkerStatus(workerId, status);
      await loadAdminWorkers();
    } catch (error) {
      console.error("Unable to update worker status", error);
    }
  };
  const handleVerifySubmit = async (e) => {
    e.preventDefault();
    if (!selectedWorker || !nicNumber || !verificationDocument || !policeReport) {
      alert("Please fill in all verification details and select files.");
      return;
    }
    try {
      await api.verifyWorker(selectedWorker.id, nicNumber, verificationDocument, policeReport);
      setShowVerifyModal(false);
      setSelectedWorker(null);
      setNicNumber("");
      setVerificationDocument(null);
      setPoliceReport(null);
      await loadAdminWorkers();
    } catch (error) {
      alert(error.message || "Failed to verify worker.");
    }
  };
  const handleRejectSubmit = async (e) => {
    e.preventDefault();
    if (!selectedWorker || !rejectionReason) {
      alert("Please select a rejection reason.");
      return;
    }
    const finalReason = rejectionReason === "Other" ? customRejectionReason : rejectionReason;
    if (!finalReason.trim()) {
      alert("Please specify the rejection reason.");
      return;
    }
    try {
      await api.rejectWorker(selectedWorker.id, finalReason);
      setShowRejectModal(false);
      setSelectedWorker(null);
      setRejectionReason("");
      setCustomRejectionReason("");
      await loadAdminWorkers();
    } catch (error) {
      alert(error.message || "Failed to reject worker.");
    }
  };
  const workerCategories = ["All", ...new Set(workers.map(worker => worker.category || "Uncategorized"))];
  const filteredWorkers = workers.filter(worker => {
    const searchText = workerSearch.toLowerCase();
    const matchesSearch = workerSearch.length === 0 ||
      worker.fullName?.toLowerCase().includes(searchText) ||
      worker.email?.toLowerCase().includes(searchText) ||
      worker.skills?.toLowerCase().includes(searchText) ||
      worker.category?.toLowerCase().includes(searchText);
    const normalizedWorkerStatus = (worker.status || "").toUpperCase();
    const matchesQuickStatus = filterStatus === "All" || normalizedWorkerStatus === filterStatus;
    const matchesStatusFilters = workerStatusFilters.length === 0 || workerStatusFilters.includes(normalizedWorkerStatus);
    const matchesRating = workerRatingFilters.length === 0 || workerRatingFilters.some(threshold => (worker.rating ?? 0) >= threshold);
    const matchesJobs = workerJobFilters.length === 0 || workerJobFilters.some(threshold => (worker.totalJobs ?? 0) >= threshold);
    const matchesCategory = workerCategoryFilter === "All" || (worker.category || "Uncategorized") === workerCategoryFilter;
    return matchesSearch && matchesQuickStatus && matchesStatusFilters && matchesRating && matchesJobs && matchesCategory;
  });
  const workerCounts = {
    total: workers.length,
    pending: workers.filter(w => w.status === "PENDING" || w.status === "Pending").length,
    verified: workers.filter(w => w.status === "VERIFIED" || w.status === "Verified").length,
    rejected: workers.filter(w => w.status === "REJECTED" || w.status === "Rejected").length,
  };
  const [activePage, setActivePage] = useState("dashboard");
  const [showFilter, setShowFilter] = useState(false);
  const [selectedRole, setSelectedRole] = useState("All");
  const [complaints, setComplaints] = useState([]);
  const [complaintsLoading, setComplaintsLoading] = useState(false);
  const [complaintsError, setComplaintsError] = useState("");
  const [complaintSearch, setComplaintSearch] = useState("");
  const [complaintFilter, setComplaintFilter] = useState("All Reports");
  const [complaintViewModal, setComplaintViewModal] = useState(null);
  const [complaintActionModal, setComplaintActionModal] = useState(null);
  const [complaintActionForm, setComplaintActionForm] = useState({
    resolutionSummary: "",
    suspensionReason: "",
    suspensionDuration: "3 days",
  });
  const [complaintActionLoading, setComplaintActionLoading] = useState(false);
  const complaintCategories = ["All Reports", "Fraud", "Payment Issues", "Fake Jobs", "Harassment", "General", ...new Set(complaints.map(c => c.category || "General"))].filter((value, index, self) => self.indexOf(value) === index);
  const filteredComplaints = complaints.filter(complaint => {
    const searchText = complaintSearch.toLowerCase();
    const matchesSearch = complaintSearch.length === 0 ||
      complaint.description?.toLowerCase().includes(searchText) ||
      complaint.jobTitle?.toLowerCase().includes(searchText) ||
      complaint.filedByName?.toLowerCase().includes(searchText) ||
      complaint.category?.toLowerCase().includes(searchText);
    const matchesCategory = complaintFilter === "All Reports" || complaint.category === complaintFilter;
    return matchesSearch && matchesCategory;
  });
  const complaintStats = {
    total: complaints.length,
    pending: complaints.filter(c => c.status === "Pending" || c.status === "Investigating").length,
    resolved: complaints.filter(c => c.status === "Resolved").length,
    fraud: complaints.filter(c => c.category === "Fraud").length,
  };
  const pieData = [
  { name: "Users", value: 8542 },
  { name: "Workers", value: 2145 },
  { name: "Jobs", value: 1245 },
];
const barData = [
  { month: "Jan", jobs: 400 },
  { month: "Feb", jobs: 700 },
  { month: "Mar", jobs: 500 },
  { month: "Apr", jobs: 900 },
  { month: "May", jobs: 1200 },
];
const lineData = [
  { day: "Mon", users: 200 },
  { day: "Tue", users: 450 },
  { day: "Wed", users: 300 },
  { day: "Thu", users: 600 },
  { day: "Fri", users: 750 },
];
  const [users, setUsers] = useState([]);
  const [usersLoading, setUsersLoading] = useState(false);
  const [userSearch, setUserSearch] = useState("");
  const [userFilter, setUserFilter] = useState("All");
  const [userActionModal, setUserActionModal] = useState(null);
  const [userFormData, setUserFormData] = useState({ fullName: "", phoneNumber: "", location: "", role: "CLIENT" });
  const [userActionLoading, setUserActionLoading] = useState(false);
  const loadUsers = async () => {
    setUsersLoading(true);
    try {
      const data = await api.getAllUsers();
      setUsers(data || []);
    } catch (e) {
      console.error('Failed to load users', e);
      setUsers([]);
    } finally {
      setUsersLoading(false);
    }
  };
  useEffect(() => {
    loadUsers();
  }, []);
  // Jobs state and actions
  const [jobs, setJobs] = useState([]);
  const [jobsLoading, setJobsLoading] = useState(false);
  const [jobSearch, setJobSearch] = useState("");
  const [jobFilter, setJobFilter] = useState("All");
  const [jobActionModal, setJobActionModal] = useState(null);
  const [jobFormData, setJobFormData] = useState({ title: "", description: "", status: "OPEN" });
  const [jobActionLoading, setJobActionLoading] = useState(false);
  const loadJobs = async () => {
    setJobsLoading(true);
    try {
      const data = await api.getAllJobs();
      setJobs(data || []);
    } catch (e) {
      console.error('Failed to load jobs', e);
      setJobs([]);
    } finally {
      setJobsLoading(false);
    }
  };
  useEffect(() => {
    loadJobs();
  }, []);
  const loadComplaints = async () => {
    setComplaintsLoading(true);
    setComplaintsError("");
    try {
      const data = await api.getAdminComplaints();
      setComplaints(data || []);
    } catch (e) {
      console.error('Failed to load complaints', e);
      setComplaints([]);
      setComplaintsError(e.message || 'Unable to load complaints.');
    } finally {
      setComplaintsLoading(false);
    }
  };
  useEffect(() => {
    loadComplaints();
  }, []);
  const updateComplaintStatusInState = async (complaint, nextStatus) => {
    setComplaintActionLoading(true);
    try {
      const updatedComplaint = await api.updateComplaintStatus(complaint.id, nextStatus);
      setComplaints(prev => prev.map(item => item.id === updatedComplaint.id ? updatedComplaint : item));
      setComplaintViewModal(prev => prev && prev.id === updatedComplaint.id ? updatedComplaint : prev);
      return updatedComplaint;
    } catch (error) {
      console.error('Failed to update complaint status', error);
      alert(error.message || 'Unable to update complaint status');
      return null;
    } finally {
      setComplaintActionLoading(false);
    }
  };
  const handleViewComplaint = (complaint) => {
    setComplaintViewModal(complaint);
  };
  const openComplaintActionModal = (complaint, mode) => {
    setComplaintActionModal({ complaint, mode });
    setComplaintActionForm({
      resolutionSummary: "",
      suspensionReason: "",
      suspensionDuration: "3 days",
    });
    setComplaintActionLoading(false);
  };
  const closeComplaintActionModal = () => {
    setComplaintActionModal(null);
    setComplaintActionLoading(false);
  };
  const handleResolveComplaint = (complaint) => {
    if (complaint.status === 'Resolved') return;
    openComplaintActionModal(complaint, 'resolve');
  };
  const handleSuspendComplaint = (complaint) => {
    if (complaint.status === 'Suspended') return;
    openComplaintActionModal(complaint, 'suspend');
  };
  const handleSubmitComplaintAction = async (e) => {
    e.preventDefault();
    if (!complaintActionModal?.complaint) return;
    const { complaint, mode } = complaintActionModal;
    const nextStatus = mode === 'resolve' ? 'Resolved' : 'Suspended';
    setComplaintActionLoading(true);
    try {
      await updateComplaintStatusInState(complaint, nextStatus);
      closeComplaintActionModal();
    } catch (error) {
      console.error('Failed to submit complaint action', error);
      alert(error.message || 'Unable to complete complaint action');
      setComplaintActionLoading(false);
    }
  };
  const openJobActionModal = (job, mode) => {
    setJobActionModal({ job, mode });
    setJobFormData({
      title: job.title || "",
      description: job.description || "",
      status: job.status || "OPEN"
    });
    setJobActionLoading(false);
  };
  const closeJobActionModal = () => {
    setJobActionModal(null);
    setJobActionLoading(false);
  };
  const handleViewJob = (job) => {
    openJobActionModal(job, "view");
  };
  const handleEditJob = (job) => {
    openJobActionModal(job, "edit");
  };
  const handleDeleteJob = (job) => {
    openJobActionModal(job, "delete");
  };
  const handleSaveJobEdit = async (e) => {
    e.preventDefault();
    if (!jobActionModal?.job) return;
    setJobActionLoading(true);
    try {
      await api.updateJob(jobActionModal.job.id, {
        title: jobFormData.title,
        description: jobFormData.description,
        status: jobFormData.status,
      });
      await loadJobs();
      closeJobActionModal();
    } catch (e) {
      console.error('Failed to update job', e);
      setJobActionLoading(false);
      alert('Update failed');
    }
  };
  const handleDeleteJobConfirmed = async (e) => {
    e.preventDefault();
    if (!jobActionModal?.job) return;
    setJobActionLoading(true);
    try {
      await api.deleteJob(jobActionModal.job.id);
      await loadJobs();
      closeJobActionModal();
    } catch (e) {
      console.error('Failed to delete job', e);
      setJobActionLoading(false);
      alert('Delete failed');
    }
  };
  const handleUpdateJobStatus = async (job, status) => {
    try {
      await api.updateJob(job.id, { status });
      await loadJobs();
    } catch (e) {
      console.error('Failed to update job status', e);
      alert('Status update failed');
    }
  };
  const openUserActionModal = (user, mode) => {
    setUserActionModal({ user, mode });
    setUserFormData({
      fullName: user.fullName || "",
      phoneNumber: user.phoneNumber || "",
      location: user.location || "",
      role: user.role || "CLIENT"
    });
    setUserActionLoading(false);
  };
  const closeUserActionModal = () => {
    setUserActionModal(null);
    setUserActionLoading(false);
  };
  const handleViewUser = (user) => {
    openUserActionModal(user, "view");
  };
  const handleEditUser = (user) => {
    openUserActionModal(user, "edit");
  };
  const handleBlockUser = (user) => {
    openUserActionModal(user, "block");
  };
  const handleSaveUserEdit = async (e) => {
    e.preventDefault();
    if (!userActionModal?.user) return;
    setUserActionLoading(true);
    try {
      await api.updateUser(userActionModal.user.id, {
        fullName: userFormData.fullName,
        phoneNumber: userFormData.phoneNumber,
        location: userFormData.location,
        role: userFormData.role,
      });
      await loadUsers();
      closeUserActionModal();
    } catch (e) {
      console.error('Failed to update user', e);
      setUserActionLoading(false);
      alert('Update failed');
    }
  };
  const handleToggleBlockUser = async (e) => {
    e.preventDefault();
    if (!userActionModal?.user) return;
    const shouldBlock = userActionModal.user.isActive !== false;
    setUserActionLoading(true);
    try {
      await api.updateUser(userActionModal.user.id, { isActive: shouldBlock ? false : true });
      await loadUsers();
      closeUserActionModal();
    } catch (e) {
      console.error('Failed to update user status', e);
      setUserActionLoading(false);
      alert('Status update failed');
    }
  };
  const handleLogout = () => {
    api.logout();
    if (typeof onLogout === 'function') {
      onLogout();
    }
  };
  // ================= DASHBOARD =================
  // ================= TOGGLE SWITCH COMPONENT =================
  const ToggleSwitch = ({ checked, onChange, defaultChecked }) => {
    const [internalChecked, setInternalChecked] = React.useState(defaultChecked || false);
    const isChecked = checked !== undefined ? checked : internalChecked;
    const handleToggle = () => {
      if (onChange) {
        onChange(!isChecked);
      } else {
        setInternalChecked(!internalChecked);
      }
    };
    return (
      <button
        type="button"
        onClick={handleToggle}
        className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
          isChecked ? "bg-orange-500" : "bg-gray-200"
        }`}
      >
        <span
          className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
            isChecked ? "translate-x-5" : "translate-x-0"
          }`}
        />
      </button>
    );
  };
  // ================= VIEW SWITCHER =================
  const renderContent = () => {
    switch (activePage) {
      case "dashboard":
        return (
          <div className="flex-1 p-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-8">
            Main Dashboard
          </h1>
          <div className="grid grid-cols-4 gap-6 mb-8">
  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-orange-500">
    <p className="text-gray-500 text-sm">
      Total Users
    </p>
    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      {dashboardStats.totalUsers.toLocaleString()}
    </h1>
    <p className="text-green-500 mt-2 text-sm">
      {dashboardStats.totalUsers === 0 ? 'No users yet' : '+ Active platform users'}
    </p>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-yellow-400">
    <p className="text-gray-500 text-sm">
      Total Workers
    </p>
    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      {dashboardStats.totalWorkers.toLocaleString()}
    </h1>
    <p className="text-green-500 mt-2 text-sm">
      {dashboardStats.totalWorkers === 0 ? 'No workers yet' : 'Verified worker accounts'}
    </p>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-green-500">
    <p className="text-gray-500 text-sm">
      Total Jobs
    </p>
    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      {dashboardStats.totalJobs.toLocaleString()}
    </h1>
    <p className="text-orange-500 mt-2 text-sm">
      {dashboardStats.totalJobs === 0 ? 'No jobs posted yet' : 'Jobs currently in the system'}
    </p>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-red-500">
    <p className="text-gray-500 text-sm">
      Online Users
    </p>
    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      {dashboardStats.onlineUsers.toLocaleString()}
    </h1>
    <p className="text-green-500 mt-2 text-sm">
      {dashboardStats.onlineUsers === 0 ? 'No active users' : 'Active within last 10 min'}
    </p>
  </div>
  </div>
  </div>
        );
      case "workers":
        return (
          <div className="flex-1 p-8">
          <h1 className="text-4xl font-bold text-orange-500 mb-8">
            Worker Verification
          </h1>
          <div className="grid grid-cols-4 gap-6 mb-8">
  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-orange-500">
    <p className="text-gray-500">Total Workers</p>
    <h1 className="text-4xl font-bold mt-2">{workerCounts.total}</h1>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-yellow-400">
    <p className="text-gray-500">Pending Workers</p>
    <h1 className="text-4xl font-bold mt-2">{workerCounts.pending}</h1>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-green-500">
    <p className="text-gray-500">Verified Workers</p>
    <h1 className="text-4xl font-bold mt-2">{workerCounts.verified}</h1>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-red-500">
    <p className="text-gray-500">Rejected Workers</p>
    <h1 className="text-4xl font-bold mt-2">{workerCounts.rejected}</h1>
  </div>
</div>
          <div className="bg-white rounded-3xl shadow-md p-6">
            <div className="flex gap-4 mb-6">
  <input
    type="text"
    value={workerSearch}
    onChange={e => setWorkerSearch(e.target.value)}
    placeholder="Search workers..."
    className="bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent cursor-pointer shadow-sm hover:border-slate-300 transition-all appearance-none pr-10 bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%236B7280%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5%201.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:0.75em_auto] bg-[right_1rem_center] bg-no-repeat"
  />
<div className="relative">
  <button
    onClick={() => setShowFilter(!showFilter)}
    className="bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent cursor-pointer shadow-sm hover:border-slate-300 transition-all appearance-none pr-10 bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%236B7280%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5%201.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:0.75em_auto] bg-[right_1rem_center] bg-no-repeat"
  >
    🔍 Filter
  </button>
  {showFilter && (
    <div className="absolute right-0 mt-2 w-64 bg-white shadow-lg rounded-2xl p-4 z-50">
      <h3 className="font-bold mb-3">
        Filter Workers
      </h3>
      <div className="mb-4">
        <p className="font-semibold mb-2">Status</p>
        <label className="block mb-1">
          <input
            type="checkbox"
            checked={workerStatusFilters.includes("VERIFIED")}
            onChange={() => setWorkerStatusFilters(prev => prev.includes("VERIFIED") ? prev.filter(item => item !== "VERIFIED") : [...prev, "VERIFIED"])}
            className="rounded border-slate-300 text-orange-500 focus:ring-orange-500 mr-2 h-4 w-4 cursor-pointer"
          /> Verified
        </label>
        <label className="block mb-1">
          <input
            type="checkbox"
            checked={workerStatusFilters.includes("PENDING")}
            onChange={() => setWorkerStatusFilters(prev => prev.includes("PENDING") ? prev.filter(item => item !== "PENDING") : [...prev, "PENDING"])}
            className="rounded border-slate-300 text-orange-500 focus:ring-orange-500 mr-2 h-4 w-4 cursor-pointer"
          /> Pending
        </label>
        <label className="block">
          <input
            type="checkbox"
            checked={workerStatusFilters.includes("REJECTED")}
            onChange={() => setWorkerStatusFilters(prev => prev.includes("REJECTED") ? prev.filter(item => item !== "REJECTED") : [...prev, "REJECTED"])}
            className="rounded border-slate-300 text-orange-500 focus:ring-orange-500 mr-2 h-4 w-4 cursor-pointer"
          /> Rejected
        </label>
      </div>
      <div className="mb-4">
        <p className="font-semibold mb-2">Rating</p>
        <label className="block mb-1">
          <input
            type="checkbox"
            checked={workerRatingFilters.includes(4.5)}
            onChange={() => setWorkerRatingFilters(prev => prev.includes(4.5) ? prev.filter(item => item !== 4.5) : [...prev, 4.5])}
            className="rounded border-slate-300 text-orange-500 focus:ring-orange-500 mr-2 h-4 w-4 cursor-pointer"
          /> 4.5+
        </label>
        <label className="block">
          <input
            type="checkbox"
            checked={workerRatingFilters.includes(4.0)}
            onChange={() => setWorkerRatingFilters(prev => prev.includes(4.0) ? prev.filter(item => item !== 4.0) : [...prev, 4.0])}
            className="rounded border-slate-300 text-orange-500 focus:ring-orange-500 mr-2 h-4 w-4 cursor-pointer"
          /> 4.0+
        </label>
      </div>
      <div className="mb-4">
        <p className="font-semibold mb-2">Jobs</p>
        <label className="block mb-1">
          <input
            type="checkbox"
            checked={workerJobFilters.includes(50)}
            onChange={() => setWorkerJobFilters(prev => prev.includes(50) ? prev.filter(item => item !== 50) : [...prev, 50])}
            className="rounded border-slate-300 text-orange-500 focus:ring-orange-500 mr-2 h-4 w-4 cursor-pointer"
          /> 50+
        </label>
        <label className="block">
          <input
            type="checkbox"
            checked={workerJobFilters.includes(100)}
            onChange={() => setWorkerJobFilters(prev => prev.includes(100) ? prev.filter(item => item !== 100) : [...prev, 100])}
            className="rounded border-slate-300 text-orange-500 focus:ring-orange-500 mr-2 h-4 w-4 cursor-pointer"
          /> 100+
        </label>
      </div>
      <div className="mb-4">
        <p className="font-semibold mb-2">Category</p>
        <select
          value={workerCategoryFilter}
          onChange={(e) => setWorkerCategoryFilter(e.target.value)}
          className="bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent cursor-pointer shadow-sm hover:border-slate-300 transition-all appearance-none pr-10 bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%236B7280%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5%201.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:0.75em_auto] bg-[right_1rem_center] bg-no-repeat"
        >
          {workerCategories.map(category => (
            <option key={category} value={category}>{category}</option>
          ))}
        </select>
      </div>
      <button
        onClick={() => {
          setWorkerStatusFilters([]);
          setWorkerRatingFilters([]);
          setWorkerJobFilters([]);
          setWorkerCategoryFilter("All");
          setShowFilter(false);
        }}
        className="w-full bg-gray-200 text-gray-700 py-2 rounded-xl mb-2"
      >
        Clear Filters
      </button>
      <button
        onClick={() => setShowFilter(false)}
        className="w-full bg-orange-500 text-white py-2 rounded-xl"
      >
        Apply Filters
      </button>
    </div>
  )}
</div>
</div>
<div className="flex gap-4 mb-6 flex-wrap">
<button
        onClick={() => setFilterStatus("All")}
        className={`px-5 py-3 rounded-2xl ${filterStatus === "All" ? "bg-orange-500 text-white" : "bg-gray-200"}`}>
        All Workers
      </button>
      <button
        onClick={() => setFilterStatus("VERIFIED")}
        className={`px-5 py-3 rounded-2xl ${filterStatus === "VERIFIED" ? "bg-green-400" : "bg-gray-200"}`}>
        Verified
      </button>
      <button
        onClick={() => setFilterStatus("PENDING")}
        className={`px-5 py-3 rounded-2xl ${filterStatus === "PENDING" ? "bg-gray-500 text-white" : "bg-gray-200"}`}>
        Pending
      </button>
      <button
        onClick={() => setFilterStatus("REJECTED")}
        className={`px-5 py-3 rounded-2xl ${filterStatus === "REJECTED" ? "bg-red-500 text-white" : "bg-gray-200"}`}>
        Rejected
      </button>
  <select
    value={workerCategoryFilter}
    onChange={(e) => setWorkerCategoryFilter(e.target.value)}
    className="bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent cursor-pointer shadow-sm hover:border-slate-300 transition-all appearance-none pr-10 bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%236B7280%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5%201.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:0.75em_auto] bg-[right_1rem_center] bg-no-repeat"
  >
    {workerCategories.map(category => (
      <option key={category} value={category}>{category === "All" ? "All Categories" : category}</option>
    ))}
  </select>
</div>
            <div className="grid grid-cols-[1.5fr_1.2fr_1.8fr_100px_80px_100px_180px] bg-slate-100 py-3 px-4 rounded-xl text-sm font-bold mb-4 text-slate-700">
              <p>Worker</p>
              <p>Category</p>
              <p>Verification / Documents</p>
              <p>Status</p>
              <p>Jobs</p>
              <p>Joined</p>
              <p>Actions</p>
            </div>
            {workerLoading ? (
            <div className="p-6 text-center text-gray-600">Loading workers...</div>
          ) : filteredWorkers.length === 0 ? (
            <div className="p-6 text-center text-gray-600">No workers found.</div>
          ) : (
            filteredWorkers.map(worker => (
              <div key={worker.id} className="grid grid-cols-[1.5fr_1.2fr_1.8fr_100px_80px_100px_180px] items-center p-4 border-b hover:bg-slate-50 transition-colors">
                <div className="min-w-0">
                  <p className="font-semibold text-slate-800">{worker.fullName || "Unnamed"}</p>
                  <p className="text-xs text-slate-400">{worker.email}</p>
                  <p className="text-xs text-slate-400">{worker.phoneNumber}</p>
                </div>
                <p className="text-slate-600">{worker.category || "Uncategorized"}</p>
                <div className="text-xs text-slate-500 space-y-1">
                  {worker.nicNumber && <p>NIC: <span className="font-semibold text-slate-700">{worker.nicNumber}</span></p>}
                  {worker.verificationDocumentUrl && (
                    <p>📄 <a href={worker.verificationDocumentUrl} target="_blank" rel="noreferrer" className="text-orange-500 font-semibold hover:underline">ID/Passport copy</a></p>
                  )}
                  {worker.policeReportUrl && (
                    <p>📄 <a href={worker.policeReportUrl} target="_blank" rel="noreferrer" className="text-orange-500 font-semibold hover:underline">Police Report</a></p>
                  )}
                  {worker.rejectionReason && (
                    <p className="text-red-500 font-medium">Reason: {worker.rejectionReason}</p>
                  )}
                  {!worker.nicNumber && !worker.verificationDocumentUrl && !worker.policeReportUrl && !worker.rejectionReason && (
                    <p className="text-gray-400 italic">No details submitted</p>
                  )}
                </div>
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${worker.status === "VERIFIED" ? "bg-emerald-50 text-emerald-700 border border-emerald-200" : worker.status === "REJECTED" ? "bg-red-50 text-red-700 border border-red-200" : "bg-amber-50 text-amber-700 border border-amber-200"}`}>
                  {worker.status}
                </span>
                <p className="text-slate-600">{worker.totalJobs ?? 0}</p>
                <p className="text-slate-500 text-sm">{worker.createdAt ? new Date(worker.createdAt).toLocaleDateString() : "-"}</p>
                <div className="flex gap-2">
                  {worker.status !== "VERIFIED" && (
                    <button
                      onClick={() => {
                        setSelectedWorker(worker);
                        setShowVerifyModal(true);
                      }}
                      className="bg-green-500 hover:bg-green-600 text-white text-xs px-3 py-2 rounded-xl transition-all cursor-pointer font-semibold shadow-sm"
                    >
                      Verify
                    </button>
                  )}
                  {worker.status !== "REJECTED" && (
                    <button
                      onClick={() => {
                        setSelectedWorker(worker);
                        setShowRejectModal(true);
                      }}
                      className="bg-red-500 hover:bg-red-600 text-white text-xs px-3 py-2 rounded-xl transition-all cursor-pointer font-semibold shadow-sm"
                    >
                      Reject
                    </button>
                  )}
                </div>
              </div>
            ))
          )}
          {showVerifyModal && selectedWorker && (
            <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
              <div className="bg-white rounded-3xl p-8 max-w-md w-full shadow-xl">
                <h2 className="text-2xl font-bold text-slate-800 mb-2">Verify Worker</h2>
                <p className="text-sm text-slate-500 mb-6">
                  Physical verification for <span className="font-semibold text-slate-700">{selectedWorker.fullName}</span>. Please verify physical documents first.
                </p>
                <form onSubmit={handleVerifySubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-semibold text-slate-700 mb-1">National ID Card (NIC) Number</label>
                    <input
                      type="text"
                      required
                      value={nicNumber}
                      onChange={(e) => setNicNumber(e.target.value)}
                      placeholder="e.g. 199405060708 or 941234567V"
                      className="w-full bg-white border border-slate-200 text-slate-800 rounded-xl px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-orange-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-slate-700 mb-1">ID Card / License / Passport Copy</label>
                    <input
                      type="file"
                      required
                      accept="image/*,application/pdf"
                      onChange={(e) => setVerificationDocument(e.target.files[0])}
                      className="w-full text-sm file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-sm file:font-semibold file:bg-orange-50 file:text-orange-700 hover:file:bg-orange-100 cursor-pointer"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-slate-700 mb-1">Police Report Copy</label>
                    <input
                      type="file"
                      required
                      accept="image/*,application/pdf"
                      onChange={(e) => setPoliceReport(e.target.files[0])}
                      className="w-full text-sm file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-sm file:font-semibold file:bg-orange-50 file:text-orange-700 hover:file:bg-orange-100 cursor-pointer"
                    />
                  </div>
                  <div className="flex gap-4 pt-4">
                    <button
                      type="button"
                      onClick={() => {
                        setShowVerifyModal(false);
                        setSelectedWorker(null);
                        setNicNumber("");
                        setVerificationDocument(null);
                        setPoliceReport(null);
                      }}
                      className="flex-1 bg-slate-100 text-slate-700 font-semibold py-2.5 rounded-xl hover:bg-slate-200 transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="flex-1 bg-green-600 text-white font-semibold py-2.5 rounded-xl hover:bg-green-700 transition-colors"
                    >
                      Verify Worker
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
          {showRejectModal && selectedWorker && (
            <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
              <div className="bg-white rounded-3xl p-8 max-w-md w-full shadow-xl">
                <h2 className="text-2xl font-bold text-slate-800 mb-2">Reject Worker</h2>
                <p className="text-sm text-slate-500 mb-6">
                  Reject verification for <span className="font-semibold text-slate-700">{selectedWorker.fullName}</span>. Please specify the reason.
                </p>
                <form onSubmit={handleRejectSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-semibold text-slate-700 mb-1">Rejection Reason</label>
                    <select
                      required
                      value={rejectionReason}
                      onChange={(e) => setRejectionReason(e.target.value)}
                      className="w-full bg-white border border-slate-200 text-slate-800 rounded-xl px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-orange-500"
                    >
                      <option value="">-- Select Reason --</option>
                      <option value="National ID number is invalid or fake">National ID number is invalid or fake</option>
                      <option value="ID copy / Driver's License copy is blurred or incorrect">ID copy / Driver's License copy is blurred or incorrect</option>
                      <option value="Police report is missing or contains criminal background flags">Police report is missing or contains criminal background flags</option>
                      <option value="Physical check failed at designated center">Physical check failed at designated center</option>
                      <option value="Other">Other (Specify below)</option>
                    </select>
                  </div>
                  {rejectionReason === "Other" && (
                    <div>
                      <label className="block text-sm font-semibold text-slate-700 mb-1">Specify Custom Reason</label>
                      <textarea
                        required
                        value={customRejectionReason}
                        onChange={(e) => setCustomRejectionReason(e.target.value)}
                        placeholder="Please provide details..."
                        rows="3"
                        className="w-full bg-white border border-slate-200 text-slate-800 rounded-xl px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-orange-500"
                      />
                    </div>
                  )}
                  <div className="flex gap-4 pt-4">
                    <button
                      type="button"
                      onClick={() => {
                        setShowRejectModal(false);
                        setSelectedWorker(null);
                        setRejectionReason("");
                        setCustomRejectionReason("");
                      }}
                      className="flex-1 bg-slate-100 text-slate-700 font-semibold py-2.5 rounded-xl hover:bg-slate-200 transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="flex-1 bg-red-600 text-white font-semibold py-2.5 rounded-xl hover:bg-red-700 transition-colors"
                    >
                      Reject Worker
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
          </div>
        </div>
        );
      case "users":
        return (
          <div className="flex-1 p-8">
          <h1 className="text-4xl font-bold text-orange-500 mb-8">
            User Management
          </h1>
<div className="grid grid-cols-4 gap-6 mb-8">
  <div className="bg-white p-6 rounded-3xl shadow-md">
    <p className="text-gray-500">Total Users</p>
    <h1 className="text-5xl font-bold mt-3">{users.length}</h1>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md">
    <p className="text-gray-500">Clients</p>
    <h1 className="text-5xl font-bold text-orange-500 mt-3">{users.filter(u => u.role === 'CLIENT').length}</h1>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md">
    <p className="text-gray-500">Workers</p>
    <h1 className="text-5xl font-bold text-green-500 mt-3">{users.filter(u => u.role === 'WORKER').length}</h1>
  </div>
  <div className="bg-white p-6 rounded-3xl shadow-md">
    <p className="text-gray-500">Blocked Users</p>
    <h1 className="text-5xl font-bold text-red-500 mt-3">{users.filter(u => u.isActive === false).length}</h1>
  </div>
</div>
  <div className="flex gap-4 mb-6">
  <input
    type="text"
    value={userSearch}
    onChange={e => setUserSearch(e.target.value)}
    placeholder="Search users..."
    className="bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent cursor-pointer shadow-sm hover:border-slate-300 transition-all appearance-none pr-10 bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%236B7280%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5%201.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:0.75em_auto] bg-[right_1rem_center] bg-no-repeat"
  />
</div>
<div className="flex gap-4 mb-6 flex-wrap">
  <button onClick={() => setUserFilter('All')} className={`px-5 py-3 rounded-2xl ${userFilter==='All' ? 'bg-orange-500 text-white' : 'bg-gray-200'}`}>
    All Users
  </button>
  <button onClick={() => setUserFilter('CLIENT')} className={`px-5 py-3 rounded-2xl ${userFilter==='CLIENT' ? 'bg-yellow-400' : 'bg-gray-200'}`}>
    Clients
  </button>
  <button onClick={() => setUserFilter('WORKER')} className={`px-5 py-3 rounded-2xl ${userFilter==='WORKER' ? 'bg-green-500 text-white' : 'bg-gray-200'}`}>
    Workers
  </button>
  <button onClick={() => setUserFilter('ADMIN')} className={`px-5 py-3 rounded-2xl ${userFilter==='ADMIN' ? 'bg-gray-500 text-white' : 'bg-gray-200'}`}>
    Admins
  </button>
  <button onClick={() => setUserFilter('BLOCKED')} className={`px-5 py-3 rounded-2xl ${userFilter==='BLOCKED' ? 'bg-red-500 text-white' : 'bg-gray-200'}`}>
    Blocked
  </button>
</div>
          <div className="bg-white rounded-3xl shadow-md p-6">
            <div className="grid grid-cols-[1.5fr_100px_1.5fr_100px_100px_180px] bg-slate-100 py-3 px-4 rounded-xl text-sm font-bold mb-4 text-slate-700">
              <p>User</p>
              <p>Role</p>
              <p>Email</p>
              <p>Status</p>
              <p>Joined</p>
              <p>Actions</p>
            </div>
            {usersLoading ? (
              <div className="p-6 text-center text-gray-600">Loading users...</div>
            ) : users.length === 0 ? (
              <div className="p-6 text-center text-gray-600">No users found.</div>
            ) : (
              users
                .filter(u => {
                  if (userFilter === 'BLOCKED') return u.isActive === false;
                  if (userFilter === 'All') return true;
                  if (['CLIENT','WORKER','ADMIN'].includes(userFilter)) return u.role === userFilter;
                  return true;
                })
                .filter(u => {
                  if (!userSearch) return true;
                  const s = userSearch.toLowerCase();
                  return (u.fullName && u.fullName.toLowerCase().includes(s)) ||
                         (u.email && u.email.toLowerCase().includes(s));
                })
                .map(u => (
                  <div key={u.id} className="grid grid-cols-[1.5fr_100px_1.5fr_100px_100px_180px] items-center p-4 border-b hover:bg-slate-50 transition-colors">
                    <div className="min-w-0">
                      <p className="font-semibold text-slate-800">{u.fullName || "Unnamed"}</p>
                      <p className="text-xs text-slate-400">{u.phoneNumber || "-"}</p>
                    </div>
                    <p><span className={`text-xs font-semibold px-2.5 py-0.5 rounded-full ${u.role === 'ADMIN' ? 'bg-indigo-50 text-indigo-700 border border-indigo-200' : u.role === 'WORKER' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-orange-50 text-orange-700 border border-orange-200'}`}>{u.role}</span></p>
                    <p className="text-slate-600 truncate">{u.email}</p>
                    <span className={`text-sm font-medium ${u.isActive ? 'text-emerald-600' : 'text-red-500'}`}>
                      {u.isActive ? 'Active' : 'Blocked'}
                    </span>
                    <p className="text-slate-500 text-sm">{u.createdAt ? new Date(u.createdAt).toLocaleDateString() : '-'}</p>
                    <div className="flex gap-2">
                      <button onClick={() => handleViewUser(u)} className="bg-blue-500 text-white px-3 py-1 rounded-lg">View</button>
                      <button onClick={() => handleEditUser(u)} className="bg-yellow-500 text-white px-3 py-1 rounded-lg">Edit</button>
                      <button onClick={() => handleBlockUser(u)} className="bg-red-500 text-white px-3 py-1 rounded-lg">Block</button>
                    </div>
                  </div>
                ))
            )}
          </div>
          {userActionModal && (
            <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4 py-6">
              <div className="w-full max-w-2xl rounded-3xl bg-white p-6 shadow-2xl">
                <div className="mb-6 flex items-start justify-between">
                  <div>
                    <p className="text-sm font-semibold uppercase tracking-wide text-orange-500">User account actions</p>
                    <h2 className="text-2xl font-bold text-gray-900">
                      {userActionModal.mode === "view" && "View user profile"}
                      {userActionModal.mode === "edit" && "Edit user profile"}
                      {userActionModal.mode === "block" && (userActionModal.user?.isActive === false ? "Unblock user" : "Block user")}
                    </h2>
                  </div>
                  <button
                    type="button"
                    onClick={closeUserActionModal}
                    className="rounded-full bg-gray-100 px-3 py-2 text-sm text-gray-600 hover:bg-gray-200"
                  >
                    ✕
                  </button>
                </div>
                {userActionModal.mode === "view" && (
                  <div className="space-y-4">
                    <div className="grid gap-4 md:grid-cols-2">
                      <div className="rounded-2xl bg-gray-50 p-4">
                        <p className="text-sm font-semibold text-gray-500">Full name</p>
                        <p className="mt-1 font-medium text-gray-900">{userActionModal.user?.fullName || "—"}</p>
                      </div>
                      <div className="rounded-2xl bg-gray-50 p-4">
                        <p className="text-sm font-semibold text-gray-500">Role</p>
                        <p className="mt-1 font-medium text-gray-900">{userActionModal.user?.role || "—"}</p>
                      </div>
                      <div className="rounded-2xl bg-gray-50 p-4">
                        <p className="text-sm font-semibold text-gray-500">Email</p>
                        <p className="mt-1 font-medium text-gray-900">{userActionModal.user?.email || "—"}</p>
                      </div>
                      <div className="rounded-2xl bg-gray-50 p-4">
                        <p className="text-sm font-semibold text-gray-500">Phone</p>
                        <p className="mt-1 font-medium text-gray-900">{userActionModal.user?.phoneNumber || "—"}</p>
                      </div>
                      <div className="rounded-2xl bg-gray-50 p-4">
                        <p className="text-sm font-semibold text-gray-500">Location</p>
                        <p className="mt-1 font-medium text-gray-900">{userActionModal.user?.location || "—"}</p>
                      </div>
                      <div className="rounded-2xl bg-gray-50 p-4">
                        <p className="text-sm font-semibold text-gray-500">Status</p>
                        <p className={`mt-1 font-medium ${userActionModal.user?.isActive === false ? "text-red-500" : "text-green-600"}`}>
                          {userActionModal.user?.isActive === false ? "Blocked" : "Active"}
                        </p>
                      </div>
                    </div>
                    <div className="flex justify-end">
                      <button
                        type="button"
                        onClick={closeUserActionModal}
                        className="rounded-2xl bg-gray-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-gray-800"
                      >
                        Close
                      </button>
                    </div>
                  </div>
                )}
                {userActionModal.mode === "edit" && (
                  <form onSubmit={handleSaveUserEdit} className="space-y-4">
                    <div className="grid gap-4 md:grid-cols-2">
                      <label className="block text-sm font-medium text-gray-700">
                        Full name
                        <input
                          type="text"
                          value={userFormData.fullName}
                          onChange={(e) => setUserFormData({ ...userFormData, fullName: e.target.value })}
                          className="mt-1 w-full rounded-2xl border border-gray-300 px-4 py-3"
                        />
                      </label>
                      <label className="block text-sm font-medium text-gray-700">
                        Phone number
                        <input
                          type="text"
                          value={userFormData.phoneNumber}
                          onChange={(e) => setUserFormData({ ...userFormData, phoneNumber: e.target.value })}
                          className="mt-1 w-full rounded-2xl border border-gray-300 px-4 py-3"
                        />
                      </label>
                      <label className="block text-sm font-medium text-gray-700">
                        Location
                        <input
                          type="text"
                          value={userFormData.location}
                          onChange={(e) => setUserFormData({ ...userFormData, location: e.target.value })}
                          className="mt-1 w-full rounded-2xl border border-gray-300 px-4 py-3"
                        />
                      </label>
                      <label className="block text-sm font-medium text-gray-700">
                        Role
                        <select
                          value={userFormData.role}
                          onChange={(e) => setUserFormData({ ...userFormData, role: e.target.value })}
                          className="mt-1 w-full rounded-2xl border border-gray-300 px-4 py-3"
                        >
                          <option value="CLIENT">Client</option>
                          <option value="WORKER">Worker</option>
                          <option value="ADMIN">Admin</option>
                        </select>
                      </label>
                    </div>
                    <div className="flex justify-end gap-3">
                      <button
                        type="button"
                        onClick={closeUserActionModal}
                        className="rounded-2xl border border-gray-300 px-5 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-50"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        disabled={userActionLoading}
                        className="rounded-2xl bg-orange-500 px-5 py-2.5 text-sm font-semibold text-white hover:bg-orange-600 disabled:opacity-70"
                      >
                        {userActionLoading ? "Saving..." : "Save changes"}
                      </button>
                    </div>
                  </form>
                )}
                {userActionModal.mode === "block" && (
                  <form onSubmit={handleToggleBlockUser} className="space-y-4">
                    <div className="rounded-2xl border border-gray-200 bg-gray-50 p-4">
                      <p className="text-sm font-semibold text-gray-500">Selected account</p>
                      <p className="mt-1 font-semibold text-gray-900">{userActionModal.user?.fullName || userActionModal.user?.email}</p>
                      <p className="text-sm text-gray-600">{userActionModal.user?.email}</p>
                      <p className={`mt-2 text-sm font-medium ${userActionModal.user?.isActive === false ? "text-red-500" : "text-green-600"}`}>
                        {userActionModal.user?.isActive === false ? "This account is currently blocked." : "This account is currently active."}
                      </p>
                    </div>
                    <p className="text-sm text-gray-600">
                      This action updates the user's status quickly and can be reversed later from the same form.
                    </p>
                    <div className="flex justify-end gap-3">
                      <button
                        type="button"
                        onClick={closeUserActionModal}
                        className="rounded-2xl border border-gray-300 px-5 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-50"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        disabled={userActionLoading}
                        className={`rounded-2xl px-5 py-2.5 text-sm font-semibold text-white ${userActionModal.user?.isActive === false ? "bg-green-600 hover:bg-green-700" : "bg-red-500 hover:bg-red-600"} disabled:opacity-70`}
                      >
                        {userActionLoading ? "Updating..." : userActionModal.user?.isActive === false ? "Unblock user" : "Block user"}
                      </button>
                    </div>
                  </form>
                )}
              </div>
            </div>
          )}
        </div>
        );
      case "jobs":
        return (
          <div className="flex-1 p-8">
        <h1 className="text-5xl font-bold text-orange-500 mb-8">
          Job Management
        </h1>
        {/* Statistics Cards */}
        <div className="grid grid-cols-4 gap-6 mb-8">
          <div className="bg-white p-6 rounded-3xl shadow-md">
            <p className="text-gray-500">Total Jobs</p>
            <h1 className="text-5xl font-bold mt-3">{jobs.length}</h1>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md">
            <p className="text-gray-500">Pending</p>
            <h1 className="text-5xl font-bold text-yellow-500 mt-3">{jobs.filter(j=> ['OPEN','PENDING','Pending','ASSIGNED'].includes(j.status)).length}</h1>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md">
            <p className="text-gray-500">Completed</p>
            <h1 className="text-5xl font-bold text-green-500 mt-3">{jobs.filter(j=> j.status === 'COMPLETED' || j.status === 'Completed').length}</h1>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md">
            <p className="text-gray-500">Cancelled</p>
            <h1 className="text-5xl font-bold text-red-500 mt-3">{jobs.filter(j=> j.status === 'CANCELLED' || j.status === 'Cancelled').length}</h1>
          </div>
        </div>
        {/* Search */}
        <div className="flex gap-4 mb-6">
          <input
            type="text"
            value={jobSearch}
            onChange={e => setJobSearch(e.target.value)}
            placeholder="Search jobs..."
            className="bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent cursor-pointer shadow-sm hover:border-slate-300 transition-all appearance-none pr-10 bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%236B7280%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5%201.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:0.75em_auto] bg-[right_1rem_center] bg-no-repeat"
          />
        </div>
        {/* Status Buttons */}
        <div className="flex gap-4 mb-6 flex-wrap">
          <button onClick={() => setJobFilter('All')} className={`px-5 py-3 rounded-2xl ${jobFilter==='All' ? 'bg-orange-500 text-white' : 'bg-gray-200'}`}>
            All Jobs
          </button>
          <button onClick={() => setJobFilter('PENDING')} className={`px-5 py-3 rounded-2xl ${jobFilter==='PENDING' ? 'bg-yellow-400' : 'bg-gray-200'}`}>
            Pending
          </button>
          <button onClick={() => setJobFilter('COMPLETED')} className={`px-5 py-3 rounded-2xl ${jobFilter==='COMPLETED' ? 'bg-green-500 text-white' : 'bg-gray-200'}`}>
            Completed
          </button>
          <button onClick={() => setJobFilter('CANCELLED')} className={`px-5 py-3 rounded-2xl ${jobFilter==='CANCELLED' ? 'bg-red-500 text-white' : 'bg-gray-200'}`}>
            Cancelled
          </button>
        </div>
        {/* Job Table */}
        <div className="bg-white rounded-3xl shadow-md p-6">
          <div className="grid grid-cols-[2fr_1.2fr_1.2fr_100px_100px_180px] bg-slate-100 py-3 px-4 rounded-xl text-sm font-bold mb-4 text-slate-700">
            <p>Job</p>
            <p>Client</p>
            <p>Worker</p>
            <p>Status</p>
            <p>Date</p>
            <p>Actions</p>
          </div>
          {jobsLoading ? (
            <div className="p-6 text-center text-gray-600">Loading jobs...</div>
          ) : jobs.length === 0 ? (
            <div className="p-6 text-center text-gray-600">No jobs found.</div>
          ) : (
            jobs
              .filter(j => {
                if (jobFilter === 'All') return true;
                if (jobFilter === 'PENDING') return ['OPEN','PENDING','Pending','ASSIGNED'].includes(j.status);
                if (jobFilter === 'COMPLETED') return j.status === 'COMPLETED' || j.status === 'Completed';
                if (jobFilter === 'CANCELLED') return j.status === 'CANCELLED' || j.status === 'Cancelled';
                return true;
              })
              .filter(j => {
                if (!jobSearch) return true;
                const s = jobSearch.toLowerCase();
                return (j.title && j.title.toLowerCase().includes(s)) ||
                       (j.clientName && j.clientName.toLowerCase().includes(s)) ||
                       (j.workerName && j.workerName.toLowerCase().includes(s));
              })
              .map(j => (
                <div key={j.id} className="grid grid-cols-[2fr_1.2fr_1.2fr_100px_100px_180px] items-center p-4 border-b hover:bg-slate-50 transition-colors">
                  <div className="min-w-0">
                    <p className="font-semibold text-slate-800 truncate">{j.title}</p>
                    <p className="text-xs text-slate-400 truncate" title={j.description}>{j.description || "-"}</p>
                  </div>
                  <p className="text-slate-600 truncate">{j.clientName || j.client?.fullName || '-'}</p>
                  <p className="text-slate-600 truncate">{j.workerName || j.worker?.fullName || '-'}</p>
                  <span className={`text-sm font-medium ${j.status && (j.status === 'COMPLETED' || j.status === 'Completed') ? 'text-emerald-600' : j.status && (['OPEN','PENDING','Pending','ASSIGNED'].includes(j.status)) ? 'text-amber-500' : 'text-red-500'}`}>
                    {j.status}
                  </span>
                  <p className="text-slate-500 text-sm">{j.createdAt ? new Date(j.createdAt).toLocaleDateString() : '-'}</p>
                  <div className="flex gap-2">
                    <button onClick={()=>handleViewJob(j)} className="bg-blue-500 text-white px-3 py-1 rounded-lg">View</button>
                    <button onClick={()=>handleEditJob(j)} className="bg-yellow-500 text-white px-3 py-1 rounded-lg">Edit</button>
                    <button onClick={()=>handleDeleteJob(j)} className="bg-red-500 text-white px-3 py-1 rounded-lg">Delete</button>
                  </div>
                </div>
              ))
          )}
        </div>
        {jobActionModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4 py-6">
            <div className="w-full max-w-2xl rounded-3xl bg-white p-6 shadow-2xl">
              <div className="mb-6 flex items-start justify-between">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-wide text-orange-500">Job actions</p>
                  <h2 className="text-2xl font-bold text-gray-900">
                    {jobActionModal.mode === "view" && "View job details"}
                    {jobActionModal.mode === "edit" && "Edit job"}
                    {jobActionModal.mode === "delete" && "Delete job"}
                  </h2>
                </div>
                <button
                  type="button"
                  onClick={closeJobActionModal}
                  className="rounded-full bg-gray-100 px-3 py-2 text-sm text-gray-600 hover:bg-gray-200"
                >
                  ✕
                </button>
              </div>
              {jobActionModal.mode === "view" && (
                <div className="space-y-4">
                  <div className="grid gap-4 md:grid-cols-2">
                    <div className="rounded-2xl bg-gray-50 p-4">
                      <p className="text-sm font-semibold text-gray-500">Title</p>
                      <p className="mt-1 font-medium text-gray-900">{jobActionModal.job?.title || "—"}</p>
                    </div>
                    <div className="rounded-2xl bg-gray-50 p-4">
                      <p className="text-sm font-semibold text-gray-500">Status</p>
                      <p className="mt-1 font-medium text-gray-900">{jobActionModal.job?.status || "—"}</p>
                    </div>
                    <div className="rounded-2xl bg-gray-50 p-4 md:col-span-2">
                      <p className="text-sm font-semibold text-gray-500">Description</p>
                      <p className="mt-1 font-medium text-gray-900">{jobActionModal.job?.description || "—"}</p>
                    </div>
                    <div className="rounded-2xl bg-gray-50 p-4">
                      <p className="text-sm font-semibold text-gray-500">Client</p>
                      <p className="mt-1 font-medium text-gray-900">{jobActionModal.job?.clientName || jobActionModal.job?.client?.fullName || "—"}</p>
                    </div>
                    <div className="rounded-2xl bg-gray-50 p-4">
                      <p className="text-sm font-semibold text-gray-500">Worker</p>
                      <p className="mt-1 font-medium text-gray-900">{jobActionModal.job?.workerName || jobActionModal.job?.worker?.fullName || "—"}</p>
                    </div>
                  </div>
                  <div className="flex justify-end">
                    <button
                      type="button"
                      onClick={closeJobActionModal}
                      className="rounded-2xl bg-gray-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-gray-800"
                    >
                      Close
                    </button>
                  </div>
                </div>
              )}
              {jobActionModal.mode === "edit" && (
                <form onSubmit={handleSaveJobEdit} className="space-y-4">
                  <div className="grid gap-4 md:grid-cols-2">
                    <label className="block text-sm font-medium text-gray-700 md:col-span-2">
                      Job title
                      <input
                        type="text"
                        value={jobFormData.title}
                        onChange={(e) => setJobFormData({ ...jobFormData, title: e.target.value })}
                        className="mt-1 w-full rounded-2xl border border-gray-300 px-4 py-3"
                      />
                    </label>
                    <label className="block text-sm font-medium text-gray-700 md:col-span-2">
                      Description
                      <textarea
                        rows="4"
                        value={jobFormData.description}
                        onChange={(e) => setJobFormData({ ...jobFormData, description: e.target.value })}
                        className="mt-1 w-full rounded-2xl border border-gray-300 px-4 py-3"
                      />
                    </label>
                    <label className="block text-sm font-medium text-gray-700">
                      Status
                      <select
                        value={jobFormData.status}
                        onChange={(e) => setJobFormData({ ...jobFormData, status: e.target.value })}
                        className="mt-1 w-full rounded-2xl border border-gray-300 px-4 py-3"
                      >
                        <option value="OPEN">Open</option>
                        <option value="PENDING">Pending</option>
                        <option value="ASSIGNED">Assigned</option>
                        <option value="COMPLETED">Completed</option>
                        <option value="CANCELLED">Cancelled</option>
                      </select>
                    </label>
                  </div>
                  <div className="flex justify-end gap-3">
                    <button
                      type="button"
                      onClick={closeJobActionModal}
                      className="rounded-2xl border border-gray-300 px-5 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={jobActionLoading}
                      className="rounded-2xl bg-orange-500 px-5 py-2.5 text-sm font-semibold text-white hover:bg-orange-600 disabled:opacity-70"
                    >
                      {jobActionLoading ? "Saving..." : "Save job"}
                    </button>
                  </div>
                </form>
              )}
              {jobActionModal.mode === "delete" && (
                <form onSubmit={handleDeleteJobConfirmed} className="space-y-4">
                  <div className="rounded-2xl border border-red-200 bg-red-50 p-4">
                    <p className="text-sm font-semibold uppercase tracking-wide text-red-500">Danger zone</p>
                    <p className="mt-2 text-lg font-semibold text-gray-900">Delete {jobActionModal.job?.title || "this job"}?</p>
                    <p className="mt-1 text-sm text-gray-600">
                      This action permanently removes the job from the management view and should be used carefully.
                    </p>
                  </div>
                  <div className="flex justify-end gap-3">
                    <button
                      type="button"
                      onClick={closeJobActionModal}
                      className="rounded-2xl border border-gray-300 px-5 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={jobActionLoading}
                      className="rounded-2xl bg-red-500 px-5 py-2.5 text-sm font-semibold text-white hover:bg-red-600 disabled:opacity-70"
                    >
                      {jobActionLoading ? "Deleting..." : "Delete job"}
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>
        )}
      </div>
        );
      case "analytics":
        return (
          <div className="flex-1 p-8 overflow-y-auto">
        <h1 className="text-4xl font-bold mb-8">
          Analytics Dashboard
        </h1>
        {/* Analytics Cards */}
        <div className="grid grid-cols-4 gap-6 mb-8">
          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-orange-500">
            <p className="text-gray-500">
              Total Users
            </p>
            <h1 className="text-5xl font-bold mt-3">
              8,542
            </h1>
            <p className="text-green-500 mt-2">
              +12% Growth
            </p>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-yellow-400">
            <p className="text-gray-500">
              Total Jobs
            </p>
            <h1 className="text-5xl font-bold mt-3">
              1,245
            </h1>
            <p className="text-green-500 mt-2">
              +8% Growth
            </p>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-green-500">
            <p className="text-gray-500">
              Revenue
            </p>
            <h1 className="text-5xl font-bold mt-3">
              LKR 1.2M
            </h1>
            <p className="text-green-500 mt-2">
              Monthly Revenue
            </p>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-red-500">
            <p className="text-gray-500">
              Complaints
            </p>
            <h1 className="text-5xl font-bold mt-3">
              84
            </h1>
            <p className="text-red-500 mt-2">
              Needs Review
            </p>
          </div>
        </div>
        {/* Charts */}
        <div className="grid grid-cols-2 gap-6 mb-8">
          {/* Bar Chart */}
          <div className="bg-white p-6 rounded-3xl shadow-md">
            <h2 className="text-2xl font-bold mb-4">
              Monthly Jobs
            </h2>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={barData}>
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Bar
                  dataKey="jobs"
                  fill="#f97316"
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
          {/* Line Chart */}
          <div className="bg-white p-6 rounded-3xl shadow-md">
            <h2 className="text-2xl font-bold mb-4">
              User Growth
            </h2>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={lineData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="day" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="users"
                  stroke="#22c55e"
                  strokeWidth={3}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
        {/* Pie Chart + Complaint Stats */}
        <div className="grid grid-cols-2 gap-6 mb-8">
          {/* Pie Chart */}
          <div className="bg-white p-6 rounded-3xl shadow-md">
            <h2 className="text-2xl font-bold mb-4">
              Worker Categories
            </h2>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={pieData}
                  dataKey="value"
                  outerRadius={100}
                  fill="#f97316"
                  label
                >
                  <Cell fill="#f97316" />
                  <Cell fill="#22c55e" />
                  <Cell fill="#eab308" />
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          {/* Complaint Analytics */}
          <div className="bg-white p-6 rounded-3xl shadow-md">
            <h2 className="text-2xl font-bold mb-6">
              Complaint Analytics
            </h2>
            <div className="space-y-6">
              <div>
                <p className="font-bold">
                  Resolved Complaints
                </p>
                <div className="w-full bg-gray-200 rounded-full h-4 mt-2">
                  <div className="bg-green-500 h-4 rounded-full w-3/4"></div>
                </div>
                <p className="text-sm text-gray-500 mt-1">
                  75%
                </p>
              </div>
              <div>
                <p className="font-bold">
                  Pending Complaints
                </p>
                <div className="w-full bg-gray-200 rounded-full h-4 mt-2">
                  <div className="bg-yellow-400 h-4 rounded-full w-1/4"></div>
                </div>
                <p className="text-sm text-gray-500 mt-1">
                  25%
                </p>
              </div>
            </div>
          </div>
        </div>
        {/* Top Workers */}
        <div className="bg-white p-6 rounded-3xl shadow-md mb-8">
          <h2 className="text-2xl font-bold mb-6">
            Most Active Workers
          </h2>
          <div className="grid grid-cols-4 bg-gray-100 p-4 rounded-2xl font-bold mb-4">
            <p>Worker</p>
            <p>Category</p>
            <p>Jobs</p>
            <p>Rating</p>
          </div>
          <div className="grid grid-cols-4 p-4 border-b">
            <p>Sunil Perera</p>
            <p>Plumbing</p>
            <p>128</p>
            <p>⭐ 4.8</p>
          </div>
          <div className="grid grid-cols-4 p-4 border-b">
            <p>Kamal Fernando</p>
            <p>Electrical</p>
            <p>96</p>
            <p>⭐ 4.6</p>
          </div>
        </div>
        {/* Recent Activity */}
        <div className="bg-white p-6 rounded-3xl shadow-md">
          <h2 className="text-2xl font-bold mb-6">
            Recent Platform Activity
          </h2>
          <div className="space-y-4">
            <div className="bg-gray-100 p-4 rounded-2xl">
              New worker registered in Plumbing category.
            </div>
            <div className="bg-gray-100 p-4 rounded-2xl">
              Complaint resolved for Job #5678.
            </div>
            <div className="bg-gray-100 p-4 rounded-2xl">
              Revenue increased by 12% this week.
            </div>
          </div>
        </div>
      </div>
        );
      case "disputes":
        return (
          <div className="flex-1 p-8 overflow-y-auto">
        <h1 className="text-4xl font-bold mb-8">
          Reports & Complaints
        </h1>
        {/* Statistics */}
        <div className="grid grid-cols-4 gap-6 mb-8">
          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-red-500">
            <p className="text-gray-500">Total Reports</p>
            <h1 className="text-5xl font-bold mt-3">{complaintStats.total}</h1>
            <p className="text-red-500 mt-2">{complaintStats.total > 0 ? `${complaintStats.total} records loaded` : 'No complaints yet'}</p>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-yellow-400">
            <p className="text-gray-500">Pending Complaints</p>
            <h1 className="text-5xl font-bold mt-3">{complaintStats.pending}</h1>
            <p className="text-yellow-500 mt-2">Under Review</p>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-green-500">
            <p className="text-gray-500">Resolved Cases</p>
            <h1 className="text-5xl font-bold mt-3">{complaintStats.resolved}</h1>
            <p className="text-green-500 mt-2">Successfully Solved</p>
          </div>
          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-orange-500">
            <p className="text-gray-500">Fraud Reports</p>
            <h1 className="text-5xl font-bold mt-3">{complaintStats.fraud}</h1>
            <p className="text-red-500 mt-2">High Risk</p>
          </div>
        </div>
        {/* Search */}
        <div className="flex gap-4 mb-6">
          <input
            type="text"
            placeholder="Search reports..."
            value={complaintSearch}
            onChange={(e) => setComplaintSearch(e.target.value)}
            className="bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent cursor-pointer shadow-sm hover:border-slate-300 transition-all appearance-none pr-10 bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%236B7280%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5%201.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:0.75em_auto] bg-[right_1rem_center] bg-no-repeat"
          />
          <select
            value={complaintFilter}
            onChange={(e) => setComplaintFilter(e.target.value)}
            className="bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent cursor-pointer shadow-sm hover:border-slate-300 transition-all appearance-none pr-10 bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%236B7280%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5%201.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:0.75em_auto] bg-[right_1rem_center] bg-no-repeat"
          >
            {complaintCategories.map(category => (
              <option key={category} value={category}>{category}</option>
            ))}
          </select>
        </div>
        {/* Filter Buttons */}
        <div className="flex gap-3 mb-8 flex-wrap">
          {complaintCategories.map(category => (
            <button
              key={category}
              onClick={() => setComplaintFilter(category)}
              className={`px-5 py-2.5 rounded-2xl text-sm font-semibold transition-all duration-150 border ${
                complaintFilter === category
                  ? category === "Fraud"
                    ? "bg-red-500 text-white border-red-500 shadow-sm"
                    : category === "Payment Issues"
                    ? "bg-amber-500 text-white border-amber-500 shadow-sm"
                    : category === "Fake Jobs"
                    ? "bg-blue-500 text-white border-blue-500 shadow-sm"
                    : category === "Harassment"
                    ? "bg-emerald-500 text-white border-emerald-500 shadow-sm"
                    : "bg-slate-800 text-white border-slate-800 shadow-sm"
                  : "bg-white text-slate-600 border-slate-200 hover:bg-slate-50 hover:text-slate-800"
              }`}
            >
              {category}
            </button>
          ))}
        </div>
        {/* Complaint Table */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-2xl font-bold">
              Active Complaints
            </h2>
            <button
              onClick={loadComplaints}
              className="bg-orange-500 text-white px-4 py-2 rounded-xl"
            >
              Refresh
            </button>
          </div>
          {complaintsLoading ? (
            <p className="text-gray-500">Loading complaints...</p>
          ) : complaintsError ? (
            <p className="text-red-500">{complaintsError}</p>
          ) : (
            <div className="overflow-x-auto">
              <div className="grid grid-cols-[60px_1.5fr_1.5fr_1fr_100px_100px_220px] bg-slate-100 py-3 px-4 rounded-2xl font-bold mb-4 text-slate-700" style={{ minWidth: 900 }}>
                <p>ID</p>
                <p>Reported By</p>
                <p>Job</p>
                <p>Category</p>
                <p>Priority</p>
                <p>Status</p>
                <p>Actions</p>
              </div>
              {filteredComplaints.length === 0 ? (
                <div className="rounded-2xl border border-dashed border-gray-300 p-6 text-center text-gray-600">
                  No complaints are available yet. Seed sample complaint data or file a complaint from the app to test the table.
                </div>
              ) : (
                filteredComplaints.map((complaint) => {
                  const priorityClass = complaint.priority === "High" ? "text-red-500" : complaint.priority === "Medium" ? "text-yellow-500" : "text-green-500";
                  const statusClass = complaint.status === "Resolved" ? "text-green-500" : complaint.status === "Investigating" ? "text-yellow-500" : "text-orange-500";
                  return (
                    <div key={complaint.id} className="grid grid-cols-[60px_1.5fr_1.5fr_1fr_100px_100px_220px] items-center p-4 border-b gap-2 hover:bg-slate-50 transition-colors" style={{ minWidth: 900 }}>
                      <p className="text-slate-800 font-semibold">#{complaint.id}</p>
                      <p className="text-slate-600 truncate">{complaint.filedByName || "Unknown"}</p>
                      <p className="text-slate-600 truncate">{complaint.jobTitle || `Job #${complaint.jobId || "?"}`}</p>
                      <p className="text-slate-600 truncate">{complaint.category || "General"}</p>
                      <span className={`${priorityClass} font-bold text-sm`}>{complaint.priority || "Low"}</span>
                      <span className={`${statusClass} font-bold text-sm`}>{complaint.status || "Pending"}</span>
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleViewComplaint(complaint)}
                          className="bg-blue-500 text-white px-3 py-1 rounded-lg"
                        >
                          View
                        </button>
                        <button
                          onClick={() => handleResolveComplaint(complaint)}
                          disabled={complaintActionLoading || complaint.status === "Resolved"}
                          className="bg-green-600 text-white px-3 py-1 rounded-lg disabled:opacity-60"
                        >
                          Resolve
                        </button>
                        <button
                          onClick={() => handleSuspendComplaint(complaint)}
                          disabled={complaintActionLoading || complaint.status === "Suspended"}
                          className="bg-red-600 text-white px-3 py-1 rounded-lg disabled:opacity-60"
                        >
                          Suspend
                        </button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          )}
        </div>
        {complaintViewModal && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-3xl shadow-xl w-full max-w-2xl p-6">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-2xl font-bold">Complaint #{complaintViewModal.id}</h3>
                  <p className="text-gray-500">{complaintViewModal.jobTitle || `Job #${complaintViewModal.jobId || "?"}`}</p>
                </div>
                <button onClick={() => setComplaintViewModal(null)} className="text-gray-500 text-2xl">×</button>
              </div>
              <div className="space-y-3 text-sm text-gray-700">
                <div className="grid grid-cols-2 gap-4">
                  <p><span className="font-semibold text-gray-500">Category:</span> <span className="font-medium text-gray-900">{complaintViewModal.category || "General"}</span></p>
                  <p><span className="font-semibold text-gray-500">Priority:</span> <span className="font-medium text-gray-900">{complaintViewModal.priority || "Low"}</span></p>
                  <p><span className="font-semibold text-gray-500">Status:</span> <span className="font-medium text-gray-900">{complaintViewModal.status || "Pending"}</span></p>
                  <p><span className="font-semibold text-gray-500">Created:</span> <span className="font-medium text-gray-900">{complaintViewModal.createdAt ? new Date(complaintViewModal.createdAt).toLocaleString() : "-"}</span></p>
                </div>

                <div className="grid grid-cols-2 gap-6 border-t border-b border-gray-100 py-4 my-2">
                  <div>
                    <h4 className="font-bold text-gray-900 mb-2">Complainer ({complaintViewModal.filedByRole || "User"})</h4>
                    <p><span className="font-semibold text-gray-500">Name:</span> <span className="font-medium text-gray-900">{complaintViewModal.filedByName || "Unknown"}</span></p>
                    <p><span className="font-semibold text-gray-500">Email:</span> <span className="font-medium text-gray-900">{complaintViewModal.filedByEmail || "-"}</span></p>
                    <p><span className="font-semibold text-gray-500">Phone:</span> <span className="font-medium text-gray-900">{complaintViewModal.filedByPhone || "-"}</span></p>
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900 mb-2">Other Party ({complaintViewModal.otherPartyRole || "User"})</h4>
                    <p><span className="font-semibold text-gray-500">Name:</span> <span className="font-medium text-gray-900">{complaintViewModal.otherPartyName || "Unknown"}</span></p>
                    <p><span className="font-semibold text-gray-500">Email:</span> <span className="font-medium text-gray-900">{complaintViewModal.otherPartyEmail || "-"}</span></p>
                    <p><span className="font-semibold text-gray-500">Phone:</span> <span className="font-medium text-gray-900">{complaintViewModal.otherPartyPhone || "-"}</span></p>
                  </div>
                </div>

                <div className="bg-gray-50 p-4 rounded-2xl">
                  <p className="font-semibold text-gray-900 mb-2">Description</p>
                  <p className="text-gray-600">{complaintViewModal.description || "No description was provided."}</p>
                </div>
              </div>
              <div className="mt-6 flex justify-end">
                <button onClick={() => setComplaintViewModal(null)} className="bg-gray-800 text-white px-4 py-2 rounded-xl">Close</button>
              </div>
            </div>
          </div>
        )}
        {complaintActionModal && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-3xl shadow-xl w-full max-w-2xl p-6">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-wide text-orange-500">
                    {complaintActionModal.mode === 'resolve' ? 'Resolve complaint' : 'Suspend complaint'}
                  </p>
                  <h3 className="text-2xl font-bold text-gray-900">
                    {complaintActionModal.mode === 'resolve' ? `Resolve #${complaintActionModal.complaint.id}` : `Suspend #${complaintActionModal.complaint.id}`}
                  </h3>
                  <p className="text-sm text-gray-500 mt-1">
                    {complaintActionModal.complaint.jobTitle || `Job #${complaintActionModal.complaint.jobId || 'N/A'}`}
                  </p>
                </div>
                <button type="button" onClick={closeComplaintActionModal} className="rounded-full bg-gray-100 px-3 py-2 text-sm text-gray-600 hover:bg-gray-200">
                  ✕
                </button>
              </div>
              <form onSubmit={handleSubmitComplaintAction} className="space-y-6">
                <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  <div className="rounded-3xl border border-gray-200 bg-gray-50 p-4">
                    <p className="text-sm font-semibold text-gray-500">Current status</p>
                    <p className="mt-1 text-lg font-semibold text-gray-900">{complaintActionModal.complaint.status || 'Pending'}</p>
                  </div>
                  <div className="rounded-3xl border border-gray-200 bg-gray-50 p-4">
                    <p className="text-sm font-semibold text-gray-500">Complaint category</p>
                    <p className="mt-1 text-lg font-semibold text-gray-900">{complaintActionModal.complaint.category || 'General'}</p>
                  </div>
                </div>
                {complaintActionModal.mode === 'resolve' ? (
                  <div className="space-y-4">
                    <label className="block text-sm font-medium text-gray-700">
                      Resolution summary
                      <textarea
                        value={complaintActionForm.resolutionSummary}
                        onChange={(e) => setComplaintActionForm({ ...complaintActionForm, resolutionSummary: e.target.value })}
                        rows="5"
                        placeholder="Add a note about how this complaint was resolved."
                        className="mt-2 w-full rounded-3xl border border-gray-300 px-4 py-3 text-sm text-gray-900"
                      />
                    </label>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <label className="block text-sm font-medium text-gray-700">
                      Suspension reason
                      <textarea
                        value={complaintActionForm.suspensionReason}
                        onChange={(e) => setComplaintActionForm({ ...complaintActionForm, suspensionReason: e.target.value })}
                        rows="4"
                        placeholder="Describe the reason for suspending this complaint."
                        className="mt-2 w-full rounded-3xl border border-gray-300 px-4 py-3 text-sm text-gray-900"
                      />
                    </label>
                    <label className="block text-sm font-medium text-gray-700">
                      Suspension duration
                      <select
                        value={complaintActionForm.suspensionDuration}
                        onChange={(e) => setComplaintActionForm({ ...complaintActionForm, suspensionDuration: e.target.value })}
                        className="mt-2 w-full rounded-3xl border border-gray-300 px-4 py-3 text-sm text-gray-900"
                      >
                        <option>1 day</option>
                        <option>3 days</option>
                        <option>7 days</option>
                        <option>30 days</option>
                      </select>
                    </label>
                  </div>
                )}
                <div className="border-t border-gray-200 pt-4 flex flex-col gap-3 sm:flex-row sm:justify-end">
                  <button type="button" onClick={closeComplaintActionModal} className="rounded-2xl border border-gray-300 px-5 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-50">
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={complaintActionLoading}
                    className="rounded-2xl bg-orange-500 px-5 py-3 text-sm font-semibold text-white hover:bg-orange-600 disabled:opacity-70"
                  >
                    {complaintActionLoading ? 'Processing...' : complaintActionModal.mode === 'resolve' ? 'Confirm resolve' : 'Confirm suspend'}
                  </button>
                </div>
              </form>
              <div className="mt-6 rounded-3xl bg-gray-50 p-4 text-sm text-gray-600">
                {complaintActionModal.mode === 'resolve'
                  ? 'This form records a resolution summary and updates the complaint status to Resolved.'
                  : 'This form captures suspension details and updates the complaint status to Suspended.'}
              </div>
            </div>
          </div>
        )}

      </div>
        );
      case "settings":
        return (
          <div className="flex-1 p-8 overflow-y-auto">
        <h1 className="text-4xl font-bold mb-8">
          Settings
        </h1>
        {/* Admin Profile */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">
          <h2 className="text-2xl font-bold mb-6">
            Admin Profile
          </h2>
          <div className="grid grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-1.5">Admin Name</label>
              <input
                value={adminName}
                onChange={e => setAdminName(e.target.value)}
                type="text"
                placeholder="Admin Name"
                className="w-full bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent shadow-sm hover:border-slate-300 transition-all"
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-1.5">Admin Email</label>
              <input
                value={adminEmail}
                onChange={e => setAdminEmail(e.target.value)}
                type="email"
                placeholder="Admin Email"
                className="w-full bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent shadow-sm hover:border-slate-300 transition-all"
              />
            </div>
          </div>

          <div className="mt-8 border-t pt-6">
            <h3 className="text-lg font-bold text-slate-800 mb-4">Change Password</h3>
            <div className="grid grid-cols-3 gap-6">
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1.5">Current Password</label>
                <input
                  value={oldPassword}
                  onChange={e => setOldPassword(e.target.value)}
                  type="password"
                  placeholder="Current Password"
                  className="w-full bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent shadow-sm hover:border-slate-300 transition-all"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1.5">New Password</label>
                <input
                  value={newPassword}
                  onChange={e => setNewPassword(e.target.value)}
                  type="password"
                  placeholder="New Password"
                  className="w-full bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent shadow-sm hover:border-slate-300 transition-all"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1.5">Confirm New Password</label>
                <input
                  value={confirmNewPassword}
                  onChange={e => setConfirmNewPassword(e.target.value)}
                  type="password"
                  placeholder="Confirm New Password"
                  className="w-full bg-white border border-slate-200 text-slate-700 rounded-2xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent shadow-sm hover:border-slate-300 transition-all"
                />
              </div>
            </div>
          </div>

          <div className="mt-6 flex items-center gap-3">
            <button
              onClick={async () => {
                if (newPassword || oldPassword || confirmNewPassword) {
                  if (!oldPassword) {
                    setMsg("Current password is required to change password");
                    return;
                  }
                  if (!newPassword) {
                    setMsg("New password is required");
                    return;
                  }
                  if (newPassword !== confirmNewPassword) {
                    setMsg("New passwords do not match");
                    return;
                  }
                }
                setSaving(true);
                setMsg(null);
                try {
                  const payload = {
                    fullName: adminName,
                    email: adminEmail,
                  };
                  if (newPassword) {
                    payload.newPassword = newPassword;
                    payload.oldPassword = oldPassword;
                  }
                  const updated = await api.updateProfile(payload);
                  setMsg('Profile saved successfully');
                  setNewPassword('');
                  setOldPassword('');
                  setConfirmNewPassword('');
                } catch (e) {
                  setMsg(e.message || 'Save failed');
                } finally {
                  setSaving(false);
                }
              }}
              className="bg-blue-500 hover:bg-blue-600 text-white px-6 py-3 rounded-2xl font-semibold transition-colors"
              disabled={saving}
            >
              {saving ? 'Saving...' : 'Save Profile'}
            </button>
            {msg && <p className="text-sm text-gray-600 font-medium">{msg}</p>}
          </div>
        </div>
        {/* System Settings */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">
          <h2 className="text-2xl font-bold mb-6">
            System Settings
          </h2>
          <div className="space-y-5">
            <div className="flex justify-between items-center">
              <p>Enable User Registrations</p>
              <ToggleSwitch checked={enableUserRegistrations} onChange={(checked) => { setEnableUserRegistrations(checked); localStorage.setItem("enableUserRegistrations", checked); }} />
            </div>
            <div className="flex justify-between items-center">
              <p>Enable Worker Verification</p>
              <ToggleSwitch checked={enableWorkerVerification} onChange={(checked) => { setEnableWorkerVerification(checked); localStorage.setItem("enableWorkerVerification", checked); }} />
            </div>
          </div>
        </div>

        {/* Notifications */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">
          <h2 className="text-2xl font-bold mb-6">
            Notification Settings
          </h2>
          <div className="space-y-5">
            <div className="flex justify-between items-center">
              <p>Complaint Alerts</p>
              <ToggleSwitch
                checked={complaintAlerts}
                onChange={async (checked) => {
                  setComplaintAlerts(checked);
                  try {
                    await api.updateProfile({ complaintAlerts: checked });
                  } catch (e) {
                    console.error("Failed to update complaint alerts setting", e);
                  }
                }}
              />
            </div>
            <div className="flex justify-between items-center">
              <p>Worker Registration Alerts</p>
              <ToggleSwitch
                checked={workerRegistrationAlerts}
                onChange={async (checked) => {
                  setWorkerRegistrationAlerts(checked);
                  try {
                    await api.updateProfile({ workerRegistrationAlerts: checked });
                  } catch (e) {
                    console.error("Failed to update worker registration alerts setting", e);
                  }
                }}
              />
            </div>
          </div>
        </div>
        {/* Danger Zone */}
        <div className="bg-white rounded-3xl shadow-md p-6 border border-red-500">
          <h2 className="text-2xl font-bold text-red-500 mb-6">
            Danger Zone
          </h2>
          <div className="flex gap-4">
            <button className="bg-red-500 text-white px-6 py-4 rounded-2xl">
              Reset System
            </button>
            <button className="bg-black text-white px-6 py-4 rounded-2xl">
              Delete Admin Account
            </button>
          </div>
        </div>
      </div>
        );
      default:
        return (
          <div className="p-8">Page not found</div>
        );
    }
  };
  return (
    <div className="flex h-screen bg-slate-50 overflow-hidden font-sans">
      {/* Sidebar */}
      <div className="w-64 bg-slate-900 text-slate-300 flex flex-col justify-between p-5 flex-shrink-0 h-full border-r border-slate-800">
        <div>
          <h1 className="text-3xl font-black text-orange-500 mb-10 tracking-wider px-2">
            SevaLink
          </h1>
          <nav className="space-y-1">
            <button
              onClick={() => setActivePage("dashboard")}
              className={`w-full text-left py-3 px-4 rounded-2xl text-sm font-semibold transition-all duration-150 flex items-center gap-3 ${
                activePage === "dashboard"
                  ? "bg-orange-500 text-white shadow-md shadow-orange-500/20"
                  : "hover:bg-slate-800/60 hover:text-white"
              }`}
            >
              <span>📊</span> Main Dashboard
            </button>
            <button
              onClick={() => setActivePage("workers")}
              className={`w-full text-left py-3 px-4 rounded-2xl text-sm font-semibold transition-all duration-150 flex items-center gap-3 ${
                activePage === "workers"
                  ? "bg-orange-500 text-white shadow-md shadow-orange-500/20"
                  : "hover:bg-slate-800/60 hover:text-white"
              }`}
            >
              <span>👷</span> Worker Verification
            </button>
            <button
              onClick={() => setActivePage("users")}
              className={`w-full text-left py-3 px-4 rounded-2xl text-sm font-semibold transition-all duration-150 flex items-center gap-3 ${
                activePage === "users"
                  ? "bg-orange-500 text-white shadow-md shadow-orange-500/20"
                  : "hover:bg-slate-800/60 hover:text-white"
              }`}
            >
              <span>👤</span> User Management
            </button>
            <button
              onClick={() => setActivePage("jobs")}
              className={`w-full text-left py-3 px-4 rounded-2xl text-sm font-semibold transition-all duration-150 flex items-center gap-3 ${
                activePage === "jobs"
                  ? "bg-orange-500 text-white shadow-md shadow-orange-500/20"
                  : "hover:bg-slate-800/60 hover:text-white"
              }`}
            >
              <span>💼</span> Job Management
            </button>
            <button
              onClick={() => setActivePage("analytics")}
              className={`w-full text-left py-3 px-4 rounded-2xl text-sm font-semibold transition-all duration-150 flex items-center gap-3 ${
                activePage === "analytics"
                  ? "bg-orange-500 text-white shadow-md shadow-orange-500/20"
                  : "hover:bg-slate-800/60 hover:text-white"
              }`}
            >
              <span>📈</span> Analytics
            </button>
            <button
              onClick={() => setActivePage("disputes")}
              className={`w-full text-left py-3 px-4 rounded-2xl text-sm font-semibold transition-all duration-150 flex items-center gap-3 ${
                activePage === "disputes"
                  ? "bg-orange-500 text-white shadow-md shadow-orange-500/20"
                  : "hover:bg-slate-800/60 hover:text-white"
              }`}
            >
              <span>⚠️</span> Reports & Complaints
            </button>
            <button
              onClick={() => setActivePage("settings")}
              className={`w-full text-left py-3 px-4 rounded-2xl text-sm font-semibold transition-all duration-150 flex items-center gap-3 ${
                activePage === "settings"
                  ? "bg-orange-500 text-white shadow-md shadow-orange-500/20"
                  : "hover:bg-slate-800/60 hover:text-white"
              }`}
            >
              <span>⚙️</span> Settings
            </button>
          </nav>
        </div>
        <button
          onClick={handleLogout}
          className="w-full text-left py-3 px-4 rounded-2xl text-sm font-semibold text-red-400 hover:bg-red-500/10 hover:text-red-300 transition-all duration-150 flex items-center gap-3"
        >
          <span>🚪</span> Logout
        </button>
      </div>
      {/* Main Content Area */}
      <div className="flex-1 flex flex-col h-full overflow-hidden">
        {/* Scrollable Content Container */}
        <div className="flex-1 overflow-y-auto bg-slate-50">
          {renderContent()}
        </div>
      </div>
    </div>
  );
}
export default App;
