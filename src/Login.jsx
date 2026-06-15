import React, { useState } from "react";
import App from "./App";
import logo from "./assets/logo.png";
import bgImage from "./assets/login-bg.png";

function Login() {

  const [isLoggedIn, setIsLoggedIn] = useState(false);

  if (isLoggedIn) {
    return <App />;
  }

  return (
<div
  className="h-screen w-full bg-cover bg-center flex items-center justify-center relative overflow-hidden"
  style={{ backgroundImage: `url(${bgImage})` }}
>

  {/* DARK OVERLAY */}
  <div className="absolute inset-0 bg-black/50"></div>

  {/* LOGIN CARD */}
 <div className="relative z-10 w-[360px] bg-white/10 backdrop-blur-xl border border-white/20 rounded-3xl px-10 py-6 shadow-2xl">

    {/* LOGO */}
    <div className="flex flex-col items-center mb-2">

      <img
        src={logo}
        alt="logo"
        className="w-48 h-48 object-contain mb-4"
      />

      <h1 className="text-3xl font-extrabold text-white -mt-8">
        SevaLink
      </h1>

      <p className="text-orange-300 tracking-[5px] text-sm mt-1">
        ADMIN PANEL
      </p>

    </div>

    {/* WELCOME */}
    <div className="text-center mb-3">

      <h2 className="text-2xl font-bold text-white mb-3">
        Welcome Back
      </h2>

      <p  className="text-gray-300 mt-1 text-[10px] leading-3">
        Securely manage workers, bookings,
        analytics, communication, and platform
        operations through the SevaLink system.
      </p>

    </div>

    {/* EMAIL */}
    <div className="mb-5">

      <label className="block text-white mb-2 font-medium">
        Admin Email
      </label>

      <input
        type="email"
        placeholder="Enter your email"
        className="w-full p-3 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
      />

    </div>

    {/* PASSWORD */}
    <div className="mb-5">

      <label className="block text-white mb-2 font-medium">
        Password
      </label>

      <input
        type="password"
        placeholder="Enter your password"
        className="w-full p-4 rounded-2xl bg-white/20 border border-white/20 text-white placeholder-gray-300 focus:outline-none focus:border-orange-400"
      />

    </div>

    {/* OPTIONS */}
    <div className="flex items-center justify-between mb-7 text-sm">

      <label className="flex items-center gap-2 text-gray-200">
        <input type="checkbox" />
        Remember me
      </label>

      <button className="text-orange-300 hover:text-orange-400">
        Forgot Password?
      </button>

    </div>

    {/* LOGIN BUTTON */}
    <button
      onClick={() => setIsLoggedIn(true)}
      className="w-full bg-orange-500 hover:bg-orange-600 text-white py-3 rounded-2xl font-bold text-base transition-all duration-300 shadow-xl"
    >
      Login
    </button>
    <p className="text-center text-gray-300 text-sm mt-6">
  © 2026 SevaLink. All Rights Reserved.
</p>

  </div>

</div>

  );
}

export default Login;