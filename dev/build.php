<?php

ini_set('log_errors', 0);

require(dirname(__FILE__) . '/setup.php');

/*
dmd\windows\bin\dmd -Jresources -Idmd\import -c pspemu\exe\Pspemu.d
*/

class DModule {
	public $builder;
	public $moduleName;
	public $imports;
	public $basePath;
	public $fileSource;
	public $fileSourceContents;
	public $fileObject;
	public $invalidObject;

	public function __construct(Builder $builder, $fileSource) {
		$this->builder       = $builder;
		$this->fileSource    = $fileSource;
		$this->fileSourceContents  = file_get_contents($fileSource);
		$this->moduleName    = $this->getModule();
		$this->imports       = $this->getImports();
		$this->basePath      = dirname($fileSource);
		$this->fileObject    = sprintf("%s/%s.obj", $builder->objects_folder, str_replace('.', '_', $this->moduleName));
		$this->invalidObject = ($this->sourceTime() != $this->objectTime());
		$this->fileSourceContents  = null;
	}

	public function sourceTime() {
		return @filemtime($this->fileSource);
	}
	
	public function sourceSize() {
		return filesize($this->fileSource);
	}

	public function objectTime() {
		return @filemtime($this->fileObject);
	}

	protected function getImports() {
		preg_match_all('@import\\s+([^;]*);@Umsu', $this->fileSourceContents, $matches);
		$modules = array();
		foreach ($matches[1] as $match) {
			foreach (explode(',', $match) as $module) {
				$module = trim($module);
				if (strlen($module)) $modules[] = $module;
			}
		}
		return $modules;
	}

	protected function getModule() {
		if (!preg_match('@module\\s+([^;]*);@Umsi', $this->fileSourceContents, $matches)) throw(new Exception("Can't find the module name."));
		return $matches[1];
	}

	public function checkAndUpdateObject() {
		if ($this->sourceSize()) {
			touch($this->fileObject, $this->sourceTime());
		} else {
			unlink($this->fileObject);
		}
	}

	public function compile() {
		@unlink($this->fileObject);
		$cmd = "{$this->builder->dmd} {$this->builder->flags} -of{$this->fileObject} -c {$this->fileSource}";
		printf("Compiling...%s\n", $cmd);
		$retval = 0;
		passthru($cmd, $retval);
		$this->checkAndUpdateObject();
	}

	public function moveObjectFromSourcePath() {
		$parts = pathinfo($this->fileSource);
		$fileObjectOld = sprintf('%s/%s.obj', $parts['dirname'], $parts['filename']);
		copy($fileObjectOld, $this->fileObject);
		unlink($fileObjectOld);
		$this->checkAndUpdateObject();
		//exit;
		//dirname($this->fileSource);
	}

	public function deleteObject() {
		@unlink($this->fileObject);
	}

	public function __toString() {
		return $this->moduleName;
	}
}

class Builder {
	public $dmd;
	public $rcc;
	public $modules = array();
	public $flags = "-Jresources -Idev\dmd2\import -noboundscheck -g -O -version=DFL_EXE -release -L/exet:nt/su:console:4.0";
	public $inverseDependences = array();
	public $exe = 'pspemu.exe';
	public $objects_folder;
	
	public function explore($moduleName, $level = 0) {
		//printf("Module: %s\n", $module);
		$this->modules[$moduleName] = $module = new DModule($this, sprintf('%s.d', str_replace('.', '/', $moduleName)));

		foreach ($module->imports as $importedModule) {
			if (substr($importedModule, 0, 7) != 'pspemu.') continue;
			$this->inverseDependences[$importedModule][] = $module;
			if (!isset($this->modules[$importedModule])) {
				$this->explore($importedModule);
			}
		}
		
		//print_r($this->inverseDependences); exit;

		return $module;
	}

	public function getInverseDependencesRecursive($module, $recursive = false) {
		static $checking = array();
		if (isset($checking[$module->moduleName])) {
			//die('recursive (' . $module->moduleName . ')');
			return array();
		}
		$checking[$module->moduleName] = true;
		$list = array();
		$clist = &$this->inverseDependences[$module->moduleName];
		if (isset($clist)) {
			foreach ($clist as $cmodule) {
				$list[] = $cmodule;
				if ($recursive) $list = array_merge($list, $this->getInverseDependencesRecursive($cmodule));
			}
		}
		unset($checking[$module->moduleName]);
		return array_values(array_unique($list));
	}

	public function getModulesToRefresh() {
		$list = array();
		foreach ($this->modules as $module) {
			if ($module->invalidObject) {
				$list[] = $module;
				$list = array_merge($list, $this->getInverseDependencesRecursive($module));
			}
		}
		return array_values(array_unique($list));
	}

	public function getModulesToRefreshBasic() {
		$list = array();
		foreach ($this->modules as $module) if ($module->invalidObject) $list[] = $module;
		return array_values(array_unique($list));
	}
	
	public function getModulesMaxTime($modules) {
		$times = array();
		foreach ($modules as $module) $times[] = $module->sourceTime();
		return max($times);
	}

	public function getObjectFiles($modules) {
		$list = array();
		foreach ($modules as $module) $list[] = $module->fileObject;
		return $list;
	}

	public function compileModules($modules) {
		if (!count($modules)) return;
		$linkFilesStr = implode(' ', $this->getFiles($modules));
		$cmd = "{$this->dmd} {$linkFilesStr} -c -op {$this->flags}";
		printf("Compiling...%s\n", $linkFilesStr);
		passthru($cmd, $retval);
		foreach ($modules as $module) {
			@$module->moveObjectFromSourcePath();
			if ($retval != 0) $module->deleteObject();
		}
		if ($retval != 0) {
			exit;
		}
	}

	public function incrementalBuild() {
		//print_r($this->getModulesToRefresh()); exit;

		@mkdir($this->objects_folder, 0777, true);

		// Multiple compilation.
		// http://www.mail-archive.com/digitalmars-d-bugs@puremagic.com/msg04613.html
		if (1) {
			$this->compileModules($this->getModulesToRefresh());
		}
		// Single compilation.
		else {
			//foreach ($this->getModulesToRefreshBasic() as $module) {
			foreach ($this->getModulesToRefresh() as $module) {
				$module->compile();
			}
		}

		$maxTime = $this->getModulesMaxTime($this->modules);
		
		// Build exe.
		if (@filemtime($this->exe) != $maxTime) {
			$linkFilesStr = implode(' ', $this->getObjectFiles($this->modules));
			
			//echo $linkFilesStr; exit;

			// Build .res
			echo `{$this->rcc} -32 resources\\psp.rc -oresources\\psp.res`;

			$cmd = "{$this->dmd} dfl.lib {$this->flags} -of\"{$this->exe}\" resources/psp.res {$linkFilesStr}";
			//printf("Linking...%s\n", $cmd);
			$retval = 0;
			passthru($cmd, $retval);
			if (($retval == 0) && filesize($this->exe) > 0) {
				touch($this->exe, $maxTime);
			} else {
				@unlink($this->exe);
				exit;
			}

			@unlink("pspemu.map");
			@unlink("pspemu.obj");
		}
	}

	public function getFiles($modules = null) {
		if ($modules === null) $modules = $this->modules;
		$list = array();
		foreach ($modules as $module) {
			$list[] = $module->fileSource;
		}
		return $list;
	}

	public function fullBuild() {
		$maxTime = $this->getModulesMaxTime($this->modules);
		
		// Build exe.
		if (@filemtime($this->exe) != $maxTime) {
			$linkFilesStr = implode(' ', $this->getFiles());
			$cmd = "{$this->dmd} dfl.lib {$this->flags} -of\"{$this->exe}\" resources/psp.res {$linkFilesStr}";
			$retval = 0;
			echo "Building {$this->exe}...";
			passthru($cmd, $retval);
			if ($retval != 0) {
				@unlink($this->exe);
				exit;
			} else {
				echo "Ok\n";
			}
		}
	}

	public function __construct() {
		$this->dmd = dirname(__FILE__) . '\\dmd2\\windows\\bin\\dmd.exe';
		$this->rcc = dirname(__FILE__) . '\\rcc\\rcc.exe';
		$this->objects_folder = dirname(__FILE__) . '/objects';
	}
}

$builder = new Builder;
$builder->explore('pspemu.exe.Pspemu');
foreach (scandir('pspemu/hle/kd') as $file) {
	if ($file[0] == '.') continue;
	list($moduleBase) = explode('.', $file);
	//echo "$file\n";
	$builder->explore('pspemu.hle.kd.' . $moduleBase);
}

if (1) {
	$builder->incrementalBuild();
} else {
	$builder->fullBuild();
}