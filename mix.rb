=begin
	./ruby mix.rb action	
=end
require 'fileutils' 
include FileUtils

mixerFile = File.dirname(__FILE__)+'/.gitmixer'

require File.dirname(__FILE__)+'/mixerFunctions'

$help = 'actions
	update: 
		name [version]
		name source target version
	replace: name source target revision
		revision: checkoutable name or "null" to remove
	delete: name
	add: name source target revision
		ex: gitmix add NAME /var/www/personal/framework/php/ /var/www/personal/webdevtool/site/'

def runMix(mixerFile, force = false)
	time = Time.now.to_f.to_s
	baseTmp = '/tmp/thoughtpush.gitmixer.'+time+'.'


	#get mix file
	
	if ! File.exists? mixerFile
		mixes = {}
	else
		mixes = Marshal.load(File.open(mixerFile).read)
	end

	#get named mix
	mixName = ARGV[1]
	mix = mixes[mixName]

	case ARGV[0]
		when 'help'
			puts $help
			return
		when 'force'
			ARGV.shift
			return runMix(mixerFile,true)
		when 'update'
			if ARGV.length < 3
				if !mix
					abort('Could not find '+mixName+' in mixer file')
				end
				
				version = ARGV[2]
			else
				if !mix
					mixes[mixName] = {}
					mix = mixes[mixName]
				end
				mix[:source] = ARGV[2]
				if ! File.directory? mix[:source]
					abort('Source is not a directory')
				end
				mix[:target] = ARGV[3]
				if ! File.directory? mix[:target]
					abort('Target is not a directory')
				end
				version = ARGV[4]
			end
			version = version ? version : 'master'
			
			#check source, make sure it is clean
			output = execute('cd '+mix[:source]+' && git status')
			match = /working directory clean/.match(output)
			if !match
				puts "Your working directory is not clean.  Clean with git clean -x -d -f";
				puts "Git output:";
				puts output
				abort()
			end
			
			#copy source over to temp location
			source = baseTmp+'source'
			execute('cp -R '+mix[:source]+' '+source)
			
			#if there was a previous source version for target, move to that revision
			if mix[:currentRevision]
				if !execute('cd '+source+' && git checkout '+mix[:currentRevision],1)
					execute('rm -Rf '+source)
					abort("Could not switch source to previous revision")
				end
			end
			
			execute('mv '+mix[:target]+'/.git '+baseTmp+'targetGit')
			execute('mv '+source+'/.git '+mix[:target])
			
			#reset repo on force
			if force == true
				execute('cd '+mix[:target]+' && git reset --hard '+version)
			end
			
			#checkout version
			if !execute('cd '+mix[:target]+' && git checkout '+version,true)
				execute('rm -Rf '+mix[:target]+'/.git')
				execute('mv '+baseTmp+'targetGit '+mix[:target]+'/.git')
				execute('rm -Rf '+source)
				abort('Checkout of version failed')
			end
			
			#reset to remove files from previous version
			execute('cd '+mix[:target]+' && git reset --hard ')
			
			#get revision on target at version
			mix[:currentRevision] = execute('cd '+mix[:target]+' && git rev-parse HEAD').split(/\s/)[0]
			
			execute('rm -Rf '+mix[:target]+'/.git')
			execute('mv '+baseTmp+'targetGit '+mix[:target]+'/.git')
			execute('rm -Rf '+source)
			
			puts 'Updated to '+version
			
		when 'delete'
			if !mix
				abort('Mix name not found')
			end
			mixes.delete(mixName)
			puts 'Deleted '+mixName
		when 'replace'
			if !mix
				abort('Mix name not found')
			end
			mix[:source] = ARGV[2]
			if ARGV[3]
				mix[:target] = ARGV[3]
				if ARGV[4]
					if ARGV[4] == 'null'
						mix.delete(:currentRevision)
					else
						mix[:currentRevision] = ARGV[4]
					end
				end
			end
			puts 'Replaced '+mixName
		when 'add'
			mixes[mixName] = {}
			mix = mixes[mixName]
			
			mix[:source] = ARGV[2][-1,1] == '/' ? ARGV[2] : ARGV[2]+'/'
			mix[:target] = ARGV[3][-1,1] == '/' ? ARGV[3] : ARGV[3]+'/'
			if ARGV[4]
				mix[:currentRevision] = ARGV[4]
			end
			puts 'Added '+mixName
		when 'show'
			mixes.each{|k,v|
				puts k
				p v
			}
	end

	#write modifications to file
	File.open(mixerFile,'w').write(Marshal.dump(mixes))
end


runMix mixerFile
