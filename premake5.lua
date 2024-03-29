workspace("ConvPhase")
	configurations({"debug", "release"})
	newoption({
		trigger = "kind",
		category = "Custom",
		description = "Kind of binary when building",
		default = "shared",
		allowed = {
			{"exe", "Executable"},
			{"static", "Static library"},
			{"shared", "Shared library"},
		}
	})
	newoption({
		trigger = "nopython",
		category = "Custom",
		description = "Disable Python bindings"
	})
	newoption({
		trigger = "haxeinclude",
		category = "Custom",
		description = "Haxe include path"
	})
	newoption({
		trigger = "pythonpath",
		category = "Custom",
		description = "Python include path"
	})
	newoption({
		trigger = "arch",
		category = "Custom",
		description = "Target architecture",
		default = "x86_64",
		allowed = {
			{"x86", "x86/x32, 32 bit architecture"},
			{"x86_64", "x86_64/x64, 64 bit architecture"},
		}
	})
	newoption({
		trigger = "pythonversion",
		category = "Custom",
		description = "Python version to link against for non-Windows systems",
		default = "3.10"
	})



	project("convphase")
		filter("options:kind=exe")
			kind("ConsoleApp")
		filter("options:kind=static")
			kind("StaticLib")
		filter("options:kind=shared")
			kind("SharedLib")
		filter("options:*")
		language("C++")
		cppdialect("C++17")
		architecture(_OPTIONS["arch"])

		files({"src/*.cpp"})
		includedirs({
			"include",
			"build/seqphase_cpp/include",
		})
		filter({"system:not windows"})
			includedirs("/usr/include/python" .. _OPTIONS["pythonversion"])
		filter({})
		if _OPTIONS["haxeInclude"] then
			includedirs({_OPTIONS["haxeInclude"]})
		elseif os.getenv("HAXEPATH") then
			includedirs({os.getenv("HAXEPATH") .. "/lib/hxcpp/4,2,1/include"})
		else
			print("Warning: No haxe include path set, consider setting it manually with --haxeInclude=<PATH>")
		end
		if _OPTIONS["pythonpath"] then
			includedirs({_OPTIONS["pythonpath"] .. "/include"})
			filter({"system:windows"})
				libdirs(_OPTIONS["pythonpath"] .. "/libs")
			filter({})
		end
			
		--libdirs({"thirdparty/python"})
		location("build")
		--targetdir("build/bin/${cfg.buildcfg}")
		--targetname("convphase")
		filter({"not options:nopython"})
			targetprefix("")
		filter({})
		links({
			"phase",
			"seqphase",
		})
		filter({"not options:nopython", "system:windows"})
			links("python3")
		filter({"not options:nopython", "system:not windows"})
			links("python" .. _OPTIONS["pythonVersion"])
		filter({})
		defines({
			"CP_PHASE_LIB",
			"HXCPP_API_LEVEL=400",
			-- "HXCPP_VISIT_ALLOCS",
			-- "HXCPP_DLL_EXPORT",
			-- "HX_SMART_STRINGS",
			-- "_CRT_SERCURE_NO_DEPRECATE",
			-- "_ALLOW_MSC_VER_MISMATCH",
			-- "_ALLOW_ITERATOR_DEBUG_LEVEL_MISMATCH",
		})
		filter("system:windows")
			defines({"HX_WINDOWS"})
		filter("options:arch=x86")
			defines("HXCPP_M32")
		filter("options:arch=x86_64")
			defines("HXCPP_M64")
		filter({})
		pic("On")
		linkoptions({})
		warnings("Extra")
		filter({"not system:windows"})
			buildoptions({"-pedantic"})
			disablewarnings({
				"unused-parameter",
				"reorder",             --warnings caused by hxcpp
				"deprecated-copy",
				"invalid-offsetof",
				"sign-compare",
				"unknown-pragmas"
			})
		filter({"options:noPython"})
			removefiles({"src/python_wrapper.cpp"})

		filter({"configurations:debug"})
			defines({"DEBUG"})
			optimize("Debug")
			symbols("On")

		filter({"configurations:release"})
			defines({"NDEBUG"})
			optimize("Full")
			--symbols("Off")



	project("phase")
		kind("SharedLib")
		language("C++")
		cppdialect("C++14")
		architecture(_OPTIONS["arch"])

		files({"phase/src/phase*/*.c", "phase/src/phase*/*.cpp"})
		includedirs({"phase/src/phase*", "include"})
		location("build")
		links({})
		defines({
			"CP_PHASE_LIB",
			"CP_PHASE_NOFILE",
			"CP_PHASE_DISABLE_COUT",
			"CP_PHASE_DISABLE_CERR",
		})
		pic("On")
		filter({"not system:windows"})
			buildoptions({"-pedantic"})
		filter({})
		linkoptions({})
		warnings("Off")
		disablewarnings({})


		filter("configurations:debug")
			defines({"DEBUG"})
			optimize("Debug")
			symbols("On")

		filter("configurations:release")
			defines({"NDEBUG"})
			optimize("Full")
			--symbols("Off")



	project("seqphase")
		kind("StaticLib")
		language("C++")
		architecture(_OPTIONS["arch"])
		location("build")
		buildmessage("Building SeqPHASE")
		files("src/dummy.cpp")

		haxeBuildCmd = {
			"{CHDIR} ../SeqPHASE/haxe &&",
			"haxe --cpp ../../build/seqphase_cpp",
			"-D static_link",
			"-D ABI=-MD",
			"-D HAXE_OUTPUT_FILE=%{cfg.buildtarget.basename}",
			"SeqPhase1.hx",
			"SeqPhase2.hx",
		}
		if _OPTIONS["arch"] == "x86" then
			table.insert(haxeBuildCmd, "-D HXCPP_M32")
		elseif _OPTIONS["arch"] == "x86_64" then
			table.insert(haxeBuildCmd, "-D HXCPP_M64")
		end

		postbuildcommands({
			table.concat(haxeBuildCmd, " ")
		})
		filter("system:windows")
			postbuildcommands({
				"{CHDIR} ../../build",
			})
		filter({})
		postbuildcommands({
			"{COPYFILE} seqphase_cpp/%{cfg.buildtarget.basename}%{cfg.buildtarget.extension} %{cfg.buildtarget.relpath}",
		})

