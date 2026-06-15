import React, { useState } from "react";
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

function App() {

  const [activePage, setActivePage] = useState("dashboard");
  const [showFilter, setShowFilter] = useState(false);
  const [selectedRole, setSelectedRole] = useState("All");
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
  const workers = [
  {
    name: "Sunil Perera",
    category: "Plumbing",
    rating: "4.8",
    status: "Verified",
    jobs: 128,
  },

  {
    name: "Kamal Fernando",
    category: "Electrical",
    rating: "4.6",
    status: "Pending",
    jobs: 96,
  },

  {
    name: "Saman Kumara",
    category: "Cleaning",
    rating: "4.5",
    status: "Rejected",
    jobs: 52,
  },
];
const users = [

  {
    name: "Nimal Perera",
    role: "Client",
    email: "nimal@gmail.com",
    status: "Active",
  },

  {
    name: "Kasun Silva",
    role: "Worker",
    email: "kasun@gmail.com",
    status: "Pending",
  },

  {
    name: "Admin User",
    role: "Admin",
    email: "admin@sevalink.com",
    status: "Active",
  },

  {
    name: "Blocked User",
    role: "Blocked",
    email: "blocked@gmail.com",
    status: "Blocked",
  },

];
  // ================= DASHBOARD =================
  if (activePage === "dashboard") {
    return (
      <div className="flex min-h-screen bg-gray-100">

        {/* Sidebar */}
        <div className="w-64 bg-gray-900 text-white p-5">

          <h1 className="text-4xl font-bold text-orange-500 mb-12">
            SevaLink
          </h1>

          <div className="space-y-4">

            <button
              onClick={() => setActivePage("dashboard")}
              className="w-full text-left bg-orange-500 hover:bg-orange-600 py-2 px-4 rounded-xl text-sm"
            >
              Main Dashboard
            </button>

            <button
              onClick={() => setActivePage("workers")}
              className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
            >
              Worker Verification
            </button>

            <button
              onClick={() => setActivePage("users")}
              className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
            >
              User Management
            </button>

      
      
            <button
  onClick={() => setActivePage("jobs")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Job Management
</button>

            <button
  onClick={() => setActivePage("chat")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Chat Monitoring
</button>

            <button
  onClick={() => setActivePage("analytics")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Analytics

</button>

           <button
  onClick={() => setActivePage("disputes")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Reports and Complaints 
</button>

            <button
  onClick={() => setActivePage("settings")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Settings
</button>

            <button className="w-full text-left hover:bg-red-500 py-2 px-4 rounded-xl text-sm">
              Logout
            </button>

          </div>

        </div>

        {/* Main Dashboard */}
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
      8,542
    </h1>

    <p className="text-green-500 mt-2 text-sm">
      +12% this month
    </p>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-yellow-400">
    <p className="text-gray-500 text-sm">
      Total Workers
    </p>

    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      2,145
    </h1>

    <p className="text-green-500 mt-2 text-sm">
      +8% this month
    </p>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-green-500">
    <p className="text-gray-500 text-sm">
      Total Jobs
    </p>

    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      1,245
    </h1>

    <p className="text-orange-500 mt-2 text-sm">
      84 Pending Jobs
    </p>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-red-500">
    <p className="text-gray-500 text-sm">
      Online Users
    </p>

    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      542
    </h1>

    <p className="text-green-500 mt-2 text-sm">
      Active Now
    </p>
  </div>
  </div>
  </div>


</div>     
);
}
  // ================= WORKERS PAGE =================
  if (activePage === "workers") {
    return (
      <div className="flex min-h-screen bg-gray-100">

        {/* Sidebar */}
        <div className="w-64 bg-gray-900 text-white p-5">

          <h1 className="text-4xl font-bold text-orange-500 mb-12">
            SevaLink
          </h1>

          <div className="space-y-4">

            <button
              onClick={() => setActivePage("dashboard")}
              className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
            >
              Main Dashboard
            </button>

            <button
              onClick={() => setActivePage("workers")}
              className="w-full text-left bg-orange-500 hover:bg-orange-600 py-2 px-4 rounded-xl text-sm"
            >
              Worker Verification
            </button>

            <button
              onClick={() => setActivePage("users")}
              className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
            >
              User Management
            </button>

             <button
  onClick={() => setActivePage("jobs")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Job Management
</button>

            <button
  onClick={() => setActivePage("chat")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Chat Monitoring
</button>

           <button
  onClick={() => setActivePage("analytics")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Analytics
</button>
             <button
  onClick={() => setActivePage("disputes")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  reports and complaints 
</button>
            <button
  onClick={() => setActivePage("settings")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Settings
</button>

            <button className="w-full text-left hover:bg-red-500 py-2 px-4 rounded-xl text-sm">
              Logout
            </button>

          </div>

        </div>

        {/* Worker Content */}
        <div className="flex-1 p-8">

          <h1 className="text-4xl font-bold text-orange-500 mb-8">
            Worker Verification
          </h1>

          <div className="bg-white rounded-3xl shadow-md p-6">
            <div className="flex gap-4 mb-6">

  <input
    type="text"
    placeholder="Search workers..."
    className="flex-1 border border-gray-300 px-5 py-4 rounded-2xl"
  />

<div className="relative">

  <button
    onClick={() => setShowFilter(!showFilter)}
    className="border border-gray-300 px-6 py-4 rounded-2xl bg-white hover:bg-gray-50"
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

        <label className="block">
          <input type="checkbox" /> Verified
        </label>

        <label className="block">
          <input type="checkbox" /> Pending
        </label>

        <label className="block">
          <input type="checkbox" /> Rejected
        </label>
      </div>

      <div className="mb-4">
        <p className="font-semibold mb-2">Rating</p>

        <label className="block">
          <input type="checkbox" /> 4.5+
        </label>

        <label className="block">
          <input type="checkbox" /> 4.0+
        </label>
      </div>

      <div className="mb-4">
        <p className="font-semibold mb-2">Jobs</p>

        <label className="block">
          <input type="checkbox" /> 50+
        </label>

        <label className="block">
          <input type="checkbox" /> 100+
        </label>
      </div>

      <button className="w-full bg-orange-500 text-white py-2 rounded-xl">
        Apply Filters
      </button>

    </div>
  )}

</div>

</div>

<div className="flex gap-4 mb-6 flex-wrap">

  <button className="bg-orange-500 text-white px-5 py-3 rounded-2xl">
    All Workers
  </button>

  <button className="bg-yellow-400 px-5 py-3 rounded-2xl">
    Plumbing
  </button>

  <button className="bg-gray-500 text-white px-5 py-3 rounded-2xl">
    Electrical
  </button>

  <button className="bg-green-500 text-white px-5 py-3 rounded-2xl">
    Cleaning
  </button>

  <button className="bg-orange-300 px-5 py-3 rounded-2xl">
    Carpentry
  </button>

  <button className="bg-gray-300 px-5 py-3 rounded-2xl">
    Painting
  </button>

</div>

            <div className="grid grid-cols-7 bg-gray-100 py-2 px-4 rounded-xl text-sm font-bold mb-4">

              <p>Worker</p>
              <p>Category</p>
              <p>Rating</p>
              <p>Status</p>
              <p>Jobs</p>
              <p>Joined</p>
              <p>Actions</p>

            </div>

            <div className="grid grid-cols-7 items-center p-4 border-b">

              <p>Sunil Perera</p>
              <p>Plumbing</p>
              <p>⭐ 4.8</p>

              <span className="text-green-500">
                Verified
              </span>

              <p>128</p>
              <p>20 May 2024</p>

              <div className="flex gap-2">

                <button className="bg-blue-500 text-white px-3 py-1 rounded-lg">
                  View
                </button>

                <button className="bg-green-500 text-white px-3 py-1 rounded-lg">
                  Verify
                </button>

                <button className="bg-red-500 text-white px-3 py-1 rounded-lg">
                  Reject
                </button>

              </div>

            </div>

          </div>

        </div>

      </div>
    );
  }

  // ================= USERS PAGE =================
  if (activePage === "users") {
    return (
      <div className="flex min-h-screen bg-gray-100">

        {/* Sidebar */}
        <div className="w-64 bg-gray-900 text-white p-5">

          <h1 className="text-4xl font-bold text-orange-500 mb-12">
            SevaLink
          </h1>

          <div className="space-y-4">

            <button
  onClick={() => setActivePage("dashboard")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
              Main Dashboard
            </button>

            <button
              onClick={() => setActivePage("workers")}
              className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
            >
              Worker Verification
            </button>

            <button
              onClick={() => setActivePage("users")}
              className="w-full text-left bg-orange-500 hover:bg-orange-600 py-2 px-4 rounded-xl text-sm"
            >
              User Management
            </button>

            <button
  onClick={() => setActivePage("jobs")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Job Management
</button>

            <button
  onClick={() => setActivePage("chat")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Chat Monitoring
</button>

            <button
  onClick={() => setActivePage("analytics")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Analytics
</button>
              <button
  onClick={() => setActivePage("disputes")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Reports and Complaints 
</button>

            <button
  onClick={() => setActivePage("settings")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Settings
</button>

            <button className="w-full text-left hover:bg-red-500 py-2 px-4 rounded-xl text-sm">
              Logout
            </button>

          </div>

        </div>

        {/* Users Content */}
        <div className="flex-1 p-8">

          <h1 className="text-4xl font-bold text-orange-500 mb-8">
            User Management
          </h1>
<div className="grid grid-cols-4 gap-6 mb-8">

  <div className="bg-white p-6 rounded-3xl shadow-md">
    <p className="text-gray-500">Total Users</p>
    <h1 className="text-5xl font-bold mt-3">8,542</h1>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md">
    <p className="text-gray-500">Clients</p>
    <h1 className="text-5xl font-bold text-orange-500 mt-3">5,200</h1>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md">
    <p className="text-gray-500">Workers</p>
    <h1 className="text-5xl font-bold text-green-500 mt-3">2,145</h1>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md">
    <p className="text-gray-500">Blocked Users</p>
    <h1 className="text-5xl font-bold text-red-500 mt-3">84</h1>
  </div>

</div>

<div className="flex gap-4 mb-6">

  <input
    type="text"
    placeholder="Search users..."
    className="flex-1 border border-gray-300 px-5 py-4 rounded-2xl"
  />

  <select className="border border-gray-300 px-5 py-4 rounded-2xl bg-white">

    <option>All Roles</option>
    <option>Clients</option>
    <option>Workers</option>
    <option>Admins</option>
    <option>Blocked</option>

  </select>

</div>

<div className="flex gap-4 mb-6 flex-wrap">

  <button className="bg-orange-500 text-white px-5 py-3 rounded-2xl">
    All Users
  </button>

  <button className="bg-yellow-400 px-5 py-3 rounded-2xl">
    Clients
  </button>

  <button className="bg-green-500 text-white px-5 py-3 rounded-2xl">
    Workers
  </button>

  <button className="bg-gray-500 text-white px-5 py-3 rounded-2xl">
    Admins
  </button>

  <button className="bg-red-500 text-white px-5 py-3 rounded-2xl">
    Blocked

  </button>

</div>
          <div className="bg-white rounded-3xl shadow-md p-6">

            <div className="grid grid-cols-6 bg-gray-100 py-2 px-4 rounded-xl text-sm font-bold mb-4">

              <p>User</p>
              <p>Role</p>
              <p>Email</p>
              <p>Status</p>
              <p>Joined</p>
              <p>Actions</p>

            </div>

            <div className="grid grid-cols-6 items-center p-4 border-b">

              <p>Nimal Perera</p>
              <p>Client</p>
              <p>nimal@gmail.com</p>

              <span className="text-green-500">
                Active
              </span>

              <p>15 May 2024</p>

              <div className="flex gap-2">

                <button className="bg-blue-500 text-white px-3 py-1 rounded-lg">
                  View
                </button>

                <button className="bg-yellow-500 text-white px-3 py-1 rounded-lg">
                  Edit
                </button>

                <button className="bg-red-500 text-white px-3 py-1 rounded-lg">
                  Delete
                </button>

              </div>

            </div>

          </div>

        </div>

      </div>
    );
  }

if (activePage === "jobs") {
  return (

    <div className="flex min-h-screen bg-gray-100">

    <div className="w-64 bg-gray-900 text-white p-5">

  <h1 className="text-4xl font-bold text-orange-500 mb-12">
    SevaLink
  </h1>

  <div className="space-y-4">

    <button
      onClick={() => setActivePage("dashboard")}
      className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
    >
      Main Dashboard
    </button>

    <button
      onClick={() => setActivePage("workers")}
      className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
    >
      Worker Verification
    </button>

    <button
      onClick={() => setActivePage("users")}
      className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
    >
      User Management
    </button>

    <button
      onClick={() => setActivePage("jobs")}
      className="w-full text-left bg-orange-500 py-2 px-4 rounded-xl text-sm"
    >
      Job Management
    </button>

    <button
  onClick={() => setActivePage("chat")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Chat Monitoring
</button>

    <button
  onClick={() => setActivePage("analytics")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Analytics
</button>
      <button
  onClick={() => setActivePage("disputes")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Reports and Complaints 
</button>
    <button
  onClick={() => setActivePage("settings")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Settings
</button>

    <button className="w-full text-left hover:bg-red-500 py-2 px-4 rounded-xl text-sm">
      Logout
    </button>

  </div>

</div>


      {/* Main Content */}
      <div className="flex-1 p-8">

        <h1 className="text-5xl font-bold text-orange-500 mb-8">
          Job Management
        </h1>

        {/* Statistics Cards */}
        <div className="grid grid-cols-4 gap-6 mb-8">

          <div className="bg-white p-6 rounded-3xl shadow-md">
            <p className="text-gray-500">Total Jobs</p>
            <h1 className="text-5xl font-bold mt-3">1,245</h1>
          </div>

          <div className="bg-white p-6 rounded-3xl shadow-md">
            <p className="text-gray-500">Pending</p>
            <h1 className="text-5xl font-bold text-yellow-500 mt-3">
              84
            </h1>
          </div>

          <div className="bg-white p-6 rounded-3xl shadow-md">
            <p className="text-gray-500">Completed</p>
            <h1 className="text-5xl font-bold text-green-500 mt-3">
              1,032
            </h1>
          </div>

          <div className="bg-white p-6 rounded-3xl shadow-md">
            <p className="text-gray-500">Cancelled</p>
            <h1 className="text-5xl font-bold text-red-500 mt-3">
              129
            </h1>
          </div>

        </div>
        <div className="grid grid-cols-4 gap-6 mb-8">

  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-orange-500">
    <p className="text-gray-500 text-sm">
      Total Users
    </p>

    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      8,542
    </h1>

    <p className="text-green-500 mt-2 text-sm">
      +12% this month
    </p>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-yellow-400">
    <p className="text-gray-500 text-sm">
      Total Workers
    </p>

    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      2,145
    </h1>

    <p className="text-green-500 mt-2 text-sm">
      +8% this month
    </p>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-green-500">
    <p className="text-gray-500 text-sm">
      Total Jobs
    </p>

    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      1,245
    </h1>

    <p className="text-orange-500 mt-2 text-sm">
      84 Pending Jobs
    </p>
  </div>

  <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-red-500">
    <p className="text-gray-500 text-sm">
      Online Users
    </p>

    <h1 className="text-5xl font-bold mt-3 text-gray-800">
      542
    </h1>

    <p className="text-green-500 mt-2 text-sm">
      Active Now
    </p>
  </div>

</div>

        {/* Search */}
        <div className="flex gap-4 mb-6">

          <input
            type="text"
            placeholder="Search jobs..."
            className="flex-1 border border-gray-300 px-5 py-4 rounded-2xl"
          />

          <select className="border border-gray-300 px-5 py-4 rounded-2xl bg-white">

            <option>All Status</option>
            <option>Pending</option>
            <option>Completed</option>
            <option>Cancelled</option>

          </select>

        </div>

        {/* Status Buttons */}
        <div className="flex gap-4 mb-6 flex-wrap">

          <button className="bg-orange-500 text-white px-5 py-3 rounded-2xl">
            All Jobs
          </button>

          <button className="bg-yellow-400 px-5 py-3 rounded-2xl">
            Pending
          </button>

          <button className="bg-green-500 text-white px-5 py-3 rounded-2xl">
            Completed
          </button>

          <button className="bg-red-500 text-white px-5 py-3 rounded-2xl">
            Cancelled
          </button>

        </div>

        {/* Job Table */}
        <div className="bg-white rounded-3xl shadow-md p-6">

          <div className="grid grid-cols-6 bg-gray-100 py-2 px-4 rounded-xl text-sm font-bold mb-4">

            <p>Job</p>
            <p>Client</p>
            <p>Worker</p>
            <p>Status</p>
            <p>Date</p>
            <p>Actions</p>

          </div>

          <div className="grid grid-cols-6 items-center p-4 border-b">

            <p>House Cleaning</p>
            <p>Nimal</p>
            <p>Saman</p>

            <span className="text-green-500">
              Completed
            </span>

            <p>15 May 2024</p>

            <div className="flex gap-2">

              <button className="bg-blue-500 text-white px-3 py-1 rounded-lg">
                View
              </button>

              <button className="bg-yellow-500 text-white px-3 py-1 rounded-lg">
                Edit
              </button>

              <button className="bg-red-500 text-white px-3 py-1 rounded-lg">
                Delete
              </button>

            </div>

          </div>

        </div>

      </div>

      </div>

    

  );
}

// ================= CHAT PAGE =================
if (activePage === "chat") {
  return (

    <div className="flex min-h-screen bg-gray-100">

      {/* Sidebar */}
      <div className="w-64 bg-gray-900 text-white p-5">

        <h1 className="text-4xl font-bold text-orange-500 mb-12">
          SevaLink
        </h1>

        <div className="space-y-4">

          <button
            onClick={() => setActivePage("dashboard")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Main Dashboard
          </button>

          <button
            onClick={() => setActivePage("workers")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Worker Verification
          </button>

          <button
            onClick={() => setActivePage("users")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            User Management
          </button>

          <button
            onClick={() => setActivePage("jobs")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Job Management
          </button>

          <button
            onClick={() => setActivePage("chat")}
            className="w-full text-left bg-orange-500 py-2 px-4 rounded-xl text-sm"
          >
            Chat Monitoring
          </button>

         <button
  onClick={() => setActivePage("analytics")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Analytics
</button>

           <button
  onClick={() => setActivePage("disputes")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Reports and Complaints 
</button>
          <button
  onClick={() => setActivePage("settings")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Settings
</button>

          <button className="w-full text-left hover:bg-red-500 py-2 px-4 rounded-xl text-sm">
            Logout
          </button>

        </div>

      </div>

      {/* Chat Layout */}
      <div className="flex flex-1">

        {/* LEFT SIDE */}
        <div className="w-1/4 bg-white border-r p-5">

          <h1 className="text-2xl font-bold mb-5">
            Conversations
          </h1>

          <input
            type="text"
            placeholder="Search chats..."
            className="w-full border px-4 py-3 rounded-2xl mb-6"
          />

          <div className="space-y-4">

            <div className="bg-gray-100 p-4 rounded-2xl cursor-pointer hover:bg-orange-100">

              <h2 className="font-bold">
                Job #5678
              </h2>

              <p className="text-sm text-gray-500">
                Nimal & Sunil
              </p>

            </div>

            <div className="bg-gray-100 p-4 rounded-2xl cursor-pointer hover:bg-orange-100">

              <h2 className="font-bold">
                Job #4582
              </h2>

              <p className="text-sm text-gray-500">
                Kasun & Amal
              </p>

            </div>

          </div>

        </div>

        {/* CENTER CHAT */}
        <div className="flex-1 flex flex-col">

          {/* Top */}
          <div className="bg-white p-5 border-b">

            <h1 className="text-2xl font-bold">
              Job #5678
            </h1>

            <p className="text-gray-500">
              Nimal Fernando & Sunil Perera
            </p>

          </div>

          {/* Messages */}
          <div className="flex-1 p-6 space-y-5 overflow-y-auto">

            <div className="flex justify-start">

              <div className="bg-gray-300 px-5 py-3 rounded-2xl max-w-sm">
<div>
  <p>When can you come?</p>

  <span className="text-xs text-gray-500">
    2:45 PM
  </span>
</div>              </div>

            </div>

            <div className="flex justify-end">

              <div className="bg-orange-500 text-white px-5 py-3 rounded-2xl max-w-sm">
                I can come by 3 PM today.
              </div>

            </div>

            <div className="flex justify-start">

              <div className="bg-gray-300 px-5 py-3 rounded-2xl max-w-sm">
                Please bring materials.

                <div className="flex justify-start">

  <div className="bg-red-500 text-white px-5 py-3 rounded-2xl max-w-sm">
    ⚠ Abusive Message Detected
  </div>

</div>
              </div>

            </div>

          </div>

          {/* Bottom Input */}
          <div className="bg-white p-4 border-t flex gap-4">

            <input
              type="text"
              placeholder="Type message..."
              className="flex-1 border px-4 py-3 rounded-2xl"
            />

            <button className="bg-orange-500 text-white px-6 rounded-2xl">
              Send
            </button>

          </div>

        </div>

        {/* RIGHT SIDE */}
        <div className="w-1/4 bg-white border-l p-5">

          <h1 className="text-2xl font-bold mb-6">
            Chat Details
          </h1>

          <div className="space-y-4">

            <p>
              <span className="font-bold">
                Job ID:
              </span> #5678
            </p>

            <p>
              <span className="font-bold">
                Client:
              </span> Nimal Fernando
            </p>

            <p>
              <span className="font-bold">
                Worker:
              </span> Sunil Perera
            </p>

            <p>
              <span className="font-bold">
                Status:
              </span>

              <span className="text-green-500 ml-2">
                Active
              </span>
            </p>

            <p>
  <span className="font-bold">
    Risk Level:
  </span>

  <span className="text-red-500 ml-2">
    Medium Risk
  </span>
</p>

            <p>
              <span className="font-bold">
                Accepted:
              </span> 28 May 2024
            </p>

          </div>

          <button className="w-full bg-orange-500 text-white py-3 rounded-2xl mt-8">
            View Job Details
          </button>
          <button className="w-full bg-red-500 text-white py-3 rounded-2xl mt-4">
  Report Conversation
</button>

<div className="bg-red-100 border border-red-300 p-4 rounded-2xl mt-6">

  <h2 className="text-red-600 font-bold text-lg">
    Scam Alert
  </h2>

  <p className="text-sm text-gray-700 mt-2">
    Worker requested external payment outside SevaLink.
  </p>

</div>

<div className="bg-yellow-100 border border-yellow-300 p-4 rounded-2xl mt-4">

  <h2 className="text-yellow-700 font-bold text-lg">
    Complaint Status
  </h2>

  <p className="text-sm text-gray-700 mt-2">
    Complaint currently under admin review.
  </p>

</div>
        </div>

      </div>

    </div>

  );
}
// ================= ANALYTICS PAGE =================
if (activePage === "analytics") {
  return (

    <div className="flex min-h-screen bg-gray-100">

      {/* Sidebar */}
      <div className="w-64 bg-gray-900 text-white p-5">

        <h1 className="text-4xl font-bold text-orange-500 mb-12">
          SevaLink
        </h1>

        <div className="space-y-4">

          <button
            onClick={() => setActivePage("dashboard")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Main Dashboard
          </button>

          <button
            onClick={() => setActivePage("workers")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Worker Verification
          </button>

          <button
            onClick={() => setActivePage("users")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            User Management
          </button>

          <button
            onClick={() => setActivePage("jobs")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Job Management
          </button>

          <button
            onClick={() => setActivePage("chat")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Chat Monitoring
          </button>

          <button
            onClick={() => setActivePage("analytics")}
            className="w-full text-left bg-orange-500 py-2 px-4 rounded-xl text-sm"
          >
            Analytics
          </button>

            <button
  onClick={() => setActivePage("disputes")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Reports and Complaints 
</button>

          <button
  onClick={() => setActivePage("settings")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Settings
</button>

          <button className="w-full text-left hover:bg-red-500 py-2 px-4 rounded-xl text-sm">
            Logout
          </button>

        </div>

      </div>

      {/* Main Content */}
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

    </div>

  );
}

// ================= REPORTS & COMPLAINTS PAGE =================
if (activePage === "disputes") {
  return (

    <div className="flex min-h-screen bg-gray-100">

      {/* Sidebar */}
      <div className="w-64 bg-gray-900 text-white p-5">

        <h1 className="text-4xl font-bold text-orange-500 mb-12">
          SevaLink
        </h1>

        <div className="space-y-4">

          <button
            onClick={() => setActivePage("dashboard")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Main Dashboard
          </button>

          <button
            onClick={() => setActivePage("workers")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Worker Verification
          </button>

          <button
            onClick={() => setActivePage("users")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            User Management
          </button>

          <button
            onClick={() => setActivePage("jobs")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Job Management
          </button>

          <button
            onClick={() => setActivePage("chat")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Chat Monitoring
          </button>

          <button
            onClick={() => setActivePage("analytics")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Analytics
          </button>

          <button
            onClick={() => setActivePage("disputes")}
            className="w-full text-left bg-orange-500 py-2 px-4 rounded-xl text-sm"
          >
            Reports & Complaints
          </button>

         <button
  onClick={() => setActivePage("settings")}
  className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
>
  Settings
</button>

          <button className="w-full text-left hover:bg-red-500 py-2 px-4 rounded-xl text-sm">
            Logout
          </button>

        </div>

      </div>

      {/* Main Content */}
      <div className="flex-1 p-8 overflow-y-auto">

        <h1 className="text-4xl font-bold mb-8">
          Reports & Complaints
        </h1>

        {/* Statistics */}
        <div className="grid grid-cols-4 gap-6 mb-8">

          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-red-500">
            <p className="text-gray-500">
              Total Reports
            </p>

            <h1 className="text-5xl font-bold mt-3">
              84
            </h1>

            <p className="text-red-500 mt-2">
              +12 New Today
            </p>
          </div>

          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-yellow-400">
            <p className="text-gray-500">
              Pending Complaints
            </p>

            <h1 className="text-5xl font-bold mt-3">
              22
            </h1>

            <p className="text-yellow-500 mt-2">
              Under Review
            </p>
          </div>

          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-green-500">
            <p className="text-gray-500">
              Resolved Cases
            </p>

            <h1 className="text-5xl font-bold mt-3">
              62
            </h1>

            <p className="text-green-500 mt-2">
              Successfully Solved
            </p>
          </div>

          <div className="bg-white p-6 rounded-3xl shadow-md border-l-4 border-orange-500">
            <p className="text-gray-500">
              Fraud Reports
            </p>

            <h1 className="text-5xl font-bold mt-3">
              11
            </h1>

            <p className="text-red-500 mt-2">
              High Risk
            </p>
          </div>

        </div>

        {/* Search */}
        <div className="flex gap-4 mb-6">

          <input
            type="text"
            placeholder="Search reports..."
            className="flex-1 border border-gray-300 px-5 py-4 rounded-2xl"
          />

          <select className="border border-gray-300 px-5 py-4 rounded-2xl bg-white">

            <option>All Categories</option>
            <option>Fraud</option>
            <option>Payment Issues</option>
            <option>Fake Jobs</option>
            <option>Harassment</option>
            <option>Abusive Messages</option>

          </select>

        </div>

        {/* Filter Buttons */}
        <div className="flex gap-4 mb-8 flex-wrap">

          <button className="bg-orange-500 text-white px-5 py-3 rounded-2xl">
            All Reports
          </button>

          <button className="bg-red-500 text-white px-5 py-3 rounded-2xl">
            Fraud
          </button>

          <button className="bg-yellow-400 px-5 py-3 rounded-2xl">
            Payment
          </button>

          <button className="bg-blue-500 text-white px-5 py-3 rounded-2xl">
            Fake Jobs
          </button>

          <button className="bg-green-500 text-white px-5 py-3 rounded-2xl">
            Harassment
          </button>

        </div>

        {/* Complaint Table */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">

          <h2 className="text-2xl font-bold mb-6">
            Active Complaints
          </h2>

          <div className="grid grid-cols-7 bg-gray-100 p-4 rounded-2xl font-bold mb-4">

            <p>ID</p>
            <p>Client</p>
            <p>Worker</p>
            <p>Issue</p>
            <p>Priority</p>
            <p>Status</p>
            <p>Actions</p>

          </div>

          <div className="grid grid-cols-7 items-center p-4 border-b">

            <p>#R1023</p>
            <p>Nimal</p>
            <p>Sunil</p>
            <p>Payment Issue</p>

            <span className="text-red-500 font-bold">
              High
            </span>

            <span className="text-yellow-500 font-bold">
              Investigating
            </span>

            <div className="flex gap-2">

              <button className="bg-blue-500 text-white px-3 py-1 rounded-lg">
                View
              </button>

              <button className="bg-green-500 text-white px-3 py-1 rounded-lg">
                Resolve
              </button>

              <button className="bg-red-500 text-white px-3 py-1 rounded-lg">
                Suspend
              </button>

            </div>

          </div>

        </div>

        {/* Fraud Alerts */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">

          <h2 className="text-2xl font-bold mb-6">
            Fraud Detection Alerts
          </h2>

          <div className="space-y-4">

            <div className="bg-red-100 border-l-4 border-red-500 p-4 rounded-2xl">
              ⚠ Worker received 8 complaints this week.
            </div>

            <div className="bg-yellow-100 border-l-4 border-yellow-500 p-4 rounded-2xl">
              ⚠ Fake payment screenshot detected.
            </div>

            <div className="bg-orange-100 border-l-4 border-orange-500 p-4 rounded-2xl">
              ⚠ Multiple spam jobs reported.
            </div>

          </div>

        </div>

        {/* Chat Evidence */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">

          <h2 className="text-2xl font-bold mb-6">
            Chat Evidence Review
          </h2>

          <div className="space-y-4">

            <div className="bg-gray-100 p-4 rounded-2xl">
              <p className="font-bold">
                Client:
              </p>

              <p>
                "The worker did not complete the job."
              </p>
            </div>

            <div className="bg-orange-100 p-4 rounded-2xl">
              <p className="font-bold">
                Worker:
              </p>

              <p>
                "I completed it yesterday."
              </p>
            </div>

          </div>

        </div>

      </div>

    </div>

  );
}

// ================= SETTINGS PAGE =================
if (activePage === "settings") {
  return (

    <div className="flex min-h-screen bg-gray-100">

      {/* Sidebar */}
      <div className="w-64 bg-gray-900 text-white p-5">

        <h1 className="text-4xl font-bold text-orange-500 mb-12">
          SevaLink
        </h1>

        <div className="space-y-4">

          <button
            onClick={() => setActivePage("dashboard")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Main Dashboard
          </button>

          <button
            onClick={() => setActivePage("workers")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Worker Verification
          </button>

          <button
            onClick={() => setActivePage("users")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            User Management
          </button>

          <button
            onClick={() => setActivePage("jobs")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Job Management
          </button>

          <button
            onClick={() => setActivePage("chat")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Chat Monitoring
          </button>

          <button
            onClick={() => setActivePage("analytics")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Analytics
          </button>

          <button
            onClick={() => setActivePage("disputes")}
            className="w-full text-left hover:bg-gray-800 py-2 px-4 rounded-xl text-sm"
          >
            Reports & Complaints
          </button>

          <button
            onClick={() => setActivePage("settings")}
            className="w-full text-left bg-orange-500 py-2 px-4 rounded-xl text-sm"
          >
            Settings
          </button>

          <button className="w-full text-left hover:bg-red-500 py-2 px-4 rounded-xl text-sm">
            Logout
          </button>

        </div>

      </div>

      {/* Main Content */}
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

            <input
              type="text"
              placeholder="Admin Name"
              className="border border-gray-300 px-5 py-4 rounded-2xl"
            />

            <input
              type="email"
              placeholder="Admin Email"
              className="border border-gray-300 px-5 py-4 rounded-2xl"
            />

            <input
              type="password"
              placeholder="New Password"
              className="border border-gray-300 px-5 py-4 rounded-2xl"
            />

            <input
              type="file"
              className="border border-gray-300 px-5 py-4 rounded-2xl bg-white"
            />

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
              <input type="checkbox" defaultChecked />
            </div>

            <div className="flex justify-between items-center">
              <p>Enable Worker Verification</p>
              <input type="checkbox" defaultChecked />
            </div>

            <div className="flex justify-between items-center">
              <p>Enable Chat Monitoring</p>
              <input type="checkbox" defaultChecked />
            </div>

            <div className="flex justify-between items-center">
              <p>Enable Fraud Detection</p>
              <input type="checkbox" defaultChecked />
            </div>

          </div>

        </div>

        {/* Security Settings */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">

          <h2 className="text-2xl font-bold mb-6">
            Security Settings
          </h2>

          <div className="space-y-5">

            <div className="flex justify-between items-center">
              <p>Two-Factor Authentication</p>
              <input type="checkbox" />
            </div>

            <div className="flex justify-between items-center">
              <p>Login Alerts</p>
              <input type="checkbox" defaultChecked />
            </div>

            <div className="flex justify-between items-center">
              <p>Session Timeout</p>
              <input type="checkbox" />
            </div>

            <div className="flex justify-between items-center">
              <p>Password Expiry</p>
              <input type="checkbox" />
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
              <input type="checkbox" defaultChecked />
            </div>

            <div className="flex justify-between items-center">
              <p>Fraud Alerts</p>
              <input type="checkbox" defaultChecked />
            </div>

            <div className="flex justify-between items-center">
              <p>Worker Registration Alerts</p>
              <input type="checkbox" />
            </div>

            <div className="flex justify-between items-center">
              <p>Payment Issue Alerts</p>
              <input type="checkbox" defaultChecked />
            </div>

          </div>

        </div>

        {/* Appearance */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">

          <h2 className="text-2xl font-bold mb-6">
            Appearance Settings
          </h2>

          <div className="space-y-5">

            <div className="flex justify-between items-center">
              <p>Dark Mode</p>
              <input type="checkbox" />
            </div>

            <div className="flex justify-between items-center">
              <p>Compact Sidebar</p>
              <input type="checkbox" />
            </div>

            <div className="flex justify-between items-center">
              <p>Enable Animations</p>
              <input type="checkbox" defaultChecked />
            </div>

          </div>

        </div>

        {/* Platform Controls */}
        <div className="bg-white rounded-3xl shadow-md p-6 mb-8">

          <h2 className="text-2xl font-bold mb-6">
            Platform Controls
          </h2>

          <div className="grid grid-cols-2 gap-4">

            <button className="bg-orange-500 text-white py-4 rounded-2xl">
              Manage Categories
            </button>

            <button className="bg-blue-500 text-white py-4 rounded-2xl">
              Manage Service Fees
            </button>

            <button className="bg-green-500 text-white py-4 rounded-2xl">
              Export Reports
            </button>

            <button className="bg-red-500 text-white py-4 rounded-2xl">
              Backup Database
            </button>

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

    </div>

  );
}
return null;
}

export default App;
