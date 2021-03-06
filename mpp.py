#!/usr/bin/python
"""
MIPS Preprocessor
by Steve Johnson and Tim Henderson

==INCLUDING FILES==
#include your_file.s

==DEFINING MACROS==
#define macro_name [global]
    move %1, %2
#end

Put %n in macros to specify where parameters go.
Add 'global' to the #define line if this macro should be accessible from all other files.

==CALLING MACROS==
    macro_name a b

==USING MACROS IN MACROS==
You can use macros inside other macros as long as the first is defined above the second.

==REGISTER RENAMING==
Define an alias like this:
@my_alias = $t0
Then you can use them just like a register.

==REPETITIONS==
Put "#repeat n" above a line to repeat that line n times. See kernel_data.s for an example.

==SCOPING==
Put curly braces around your code on their own lines to make all labels and aliases valid only within that scope.
"""


"""
    number_user_programs $dst
    user_program $dst x
"""

import string, sys, re

global_macros = {}
kernel_macros = {}
max_user_programs = 16
main_count = 0
label_count = 0
main_labels = list()
var_split = re.compile(r'\s*=\s*')
strip_comments = False
first_prog = 0
magic_strings = []

def get_file_text(f1):
    #process includes
    s = ""
    in_lines = []
    included = []
    for line in f1:
        stripped = line.strip()
        if stripped.startswith("#include"):
            linesplit = stripped.split()
            arg = ' '.join(linesplit[1:])
            if arg not in included:
                included.append(arg)
                f3 = open(arg, 'r')
                text = get_file_text(f3)
                if not strip_comments:
                    text = '\n###'+arg+'###\n' + text + '\n###end '+arg+'###\n'
                f3.close()
                in_lines.append(text)
        else:
            in_lines.append(line)
    return ''.join(in_lines)

def make_kernel_macros():
    '''creates specialized macros'''
    global kernel_macros
    
    magic_prompt_string = ''
    if len(magic_strings):
        magic_prompt_string = '    .asciiz "'+''.join(magic_strings) + '"\n'
    
    number_user_programs = ''
    if not strip_comments:
        number_user_programs += ' '*4 + '#'*16 + ' start number_user_programs '  + '#'*16 + '\n'
    number_user_programs += ' '*4 + 'li      $s1 &main_count&'
    if not strip_comments:
        number_user_programs += ' '*4 + '#'*17 + ' end number_user_programs '  + '#'*17 + '\n'
    number_user_programs = ''.join(
        process_lines(number_user_programs, True, False)
    )
    
    load_user_programs = ''
    if not strip_comments:
        load_user_programs += ' '*4 + '#'*16 + ' start load_user_programs ' +  '#'*16 + '\n'
    load_user_programs += ' '*4 + '__save_frame\n'
    load_user_programs += ' '*4 + 'la      $s0 user_program_locations\n'
    for i in range(main_count):
        load_user_programs += ' '*4 + 'la      $s1 &main_labels['+str(i)+']&\n'
        load_user_programs += ' '*4 + 'sw      $s1 '+str(i*4)+'($s0)\n'
    load_user_programs += ' '*4 + '__restore_frame\n'
    if not strip_comments:
        load_user_programs += ' '*4 + '#'*17 + ' end load_user_programs ' + '#'*17 + '\n'
    load_user_programs = ''.join(
        process_lines(load_user_programs, True, False)
    )
    
    load_first_program = ''
    if not strip_comments:
        load_first_program += '    '+"#"*16+' start load_first_program '+'#'*16+'\n'
    load_first_program += "    la      $s0  " + "user_program_locations\n"
    load_first_program += "    lw      $s1  " + "%s($s0)\n" % str(first_prog)
    load_first_program += "    li      $s2  " + "%s\n" % str(first_prog)
    load_first_program = ''.join(
        process_lines(load_first_program, True, False)
    )
    if not strip_comments:
        load_first_program += ' '*4 + '#'*17 + ' end load_first_program ' + '#'*17 + '\n'
    
    kernel_macros.update({
        'number_user_programs':number_user_programs, 
        'load_user_programs':load_user_programs,
        'load_first_program':load_first_program,
        'magic_prompt_string':magic_prompt_string
    })

def post_process_kernel_macro(macro_text):
    '''to be called after arg replacement is finished'''
    r = re.compile(r'\&.*\&')
    exprs = r.findall(macro_text)
    for expr in exprs:
        exec "rep = " + expr[1:-1] in globals()
        macro_text = macro_text.replace(expr, str(rep))
    return macro_text

#if specified, rename all the labels so they don't conflict with
#tim&steve's kernel labels
def substitute_labels(s):
    global main_count, label_count
    line_list = s.split('\n')
    
    replacements = []
    label_test = re.compile(r'^([a-zA-Z0-9_]+):( |$)')
    label_strip = re.compile(r'__u\d+$')
    in_macro = False
    for line in line_list:
        linestrip = line.strip()
        if linestrip.startswith('#define'): in_macro = True
        if linestrip.startswith('#end'): in_macro = False
        if len(linestrip) > 0 and not in_macro:
            r =  label_test.match(linestrip)
            if r:
                label = r.groups()[0]
                if label == 'main':
                    replacements.append((
                        re.compile(r'\b'+label+r'\b'),
                        label+'_'+str(main_count)
                    ))
                    main_labels.append(label+'_'+str(main_count))
                    main_count += 1
                    if main_count >= max_user_programs:
                        raise Exception, "to many user programs added"
                else:
                    replacements.append((
                        re.compile(r'\b'+label+r'\b'),
                        label_strip.split(label)[0]+'__u'+str(label_count)
                    ))
                    label_count += 1
    for r, new in replacements:
        s = r.sub(new, s)
    return s

def rep_line(line, local_macros, use_kernel_macros):
    #process macros
    global global_macros
    out_lines = []
    linesplit = line.split()
    if len(linesplit) > 0:
        mtext = ""
        name = linesplit[0]
        #See if first keyword is a local or global macro, set mtext if found
        if string.lower(name) in global_macros.keys():
            mtext = global_macros[name]
        if string.lower(name) in local_macros.keys():
            mtext = local_macros[name]
        if use_kernel_macros and string.lower(name) in kernel_macros.keys():
            mtext = kernel_macros[name]
            
        #if keyword is a macro...
        if mtext != "":
            #if macro has arguments...
            if len(linesplit) > 1:
                #walk comma-delimited arg list
                arg_num = len(linesplit) - 1
                arg_list_string = ' '.join(linesplit[1:])
                arg_list = [t.strip() for t in arg_list_string.split()]
                while arg_num > 0:
                    #replace expression with argument
                    mtext = mtext.replace("%"+str(arg_num), arg_list[arg_num-1])
                    arg_num -= 1
            if use_kernel_macros and string.lower(name) in kernel_macros.keys():
                mtext = post_process_kernel_macro(mtext)
            mtext = substitute_labels(mtext)
            #append macro text (possibly transformed) to output
            out_lines.append(process_lines(mtext, use_kernel_macros, local_macros))
        else:
            out_lines.append(line)
    else:
        out_lines.append(line)
    return out_lines

def rep_names(lines, names):
    
    for i, line in enumerate(lines):
        rep = False
        for name in names.keys():
            nameloc = lines[i].find(name)
            hashsign = lines[i].find('#')
            r = re.compile(r'(\W)'+name+'(\W|$)')
            gs = r.search(lines[i])
            while gs and nameloc != -1 and (nameloc < hashsign or hashsign == -1):
                gs = gs.groups()
                if nameloc != -1 and (nameloc < hashsign or hashsign == -1):
                    rep = True
                    lines[i] = r.sub(gs[0]+names[name]+gs[1], lines[i], 1)
                nameloc = lines[i].find(name)
                hashsign = lines[i].find('#')
                gs = r.search(lines[i])
            if rep and lines[i][-1] != '>':
                line = line.lstrip().rstrip()
                hashsign = line.find('#')
                if hashsign == -1: hashsign = len(line)
                lines[i] += ' # ::-> ' + line[:hashsign] + '>'
        
    
    return lines;

def process_lines(s, kernel, use_kernel_macros, local_macros=dict(), toplevel=False):
    global global_macros
    
    in_lines = s.split('\n')
    
    in_macro = False
    is_global = False
    #out_lines = list()
    
    repetitions = 1
    
    macro_name = ""
    scopes = [[]]
    varnames = [dict()]
    cm_varnames = None #current macro variable names
    for line in in_lines:
        kw = string.lower(line.strip())
        if kw.startswith('#define'):
            #start defining macro, get its name and init a list of its lines
            if in_macro: print "Macro error."
            in_macro = True
            linesplit = line.split()
            macro_name = string.lower(linesplit[1])
            is_global = False
            if strip_comments:
                start_text = ''
            else:
                start_text = ' '*4 + '#'*16 + ' start ' + macro_name + ' ' + '#'*16
            if len(linesplit) > 2 and string.lower(linesplit[2]) == 'global':
                is_global = True
            if is_global:
                global_macros[macro_name] = [start_text]
            else:
                local_macros[macro_name] = [start_text]
            cm_varnames = dict()
        elif kw.startswith('#end'):
            #concatenate the lines and stop defining the macro
            in_macro = False
            if strip_comments:
                end_text = ''
            else:
                end_text = ' '*4 + '#'*17 + ' end ' + macro_name + ' ' + '#'*17
            if macro_name in local_macros:
                local_macros[macro_name].append(end_text)
                local_macros[macro_name] = rep_names(local_macros[macro_name], cm_varnames)
                local_macros[macro_name] = "\n".join(local_macros[macro_name])
            if macro_name in global_macros:
                global_macros[macro_name].append(end_text)
                global_macros[macro_name] = rep_names(global_macros[macro_name], cm_varnames)
                global_macros[macro_name] = "\n".join(global_macros[macro_name])
            
            cm_varnames = None
        elif kw.startswith('#repeat'):
            linesplit = line.split()
            if len(linesplit) == 2:
                repetitions = int(linesplit[1])
        elif kw.startswith('{'):
            #print '{'
            scopes.append(list())
            varnames.append(dict())
        elif kw.startswith('}'):
            #print '}'
            l = scopes.pop()
            names = varnames.pop()
            #print l
            lines = substitute_labels('\n'.join(l)).split('\n')
            lines = rep_names(lines, names)
            scopes[-1].extend(lines)
            #print lines
            #print scopes[-1][-3:]
        elif kw.startswith('@'): #variable name
            name = var_split.split(line.lstrip().rstrip())
            if len(name) != 2: raise Exception, 'Syntax Error in variable name line = \n' + line
            if in_macro:
                if cm_varnames.has_key(name[0]):
                    raise Exception, 'Syntax Error name "%s" already defined in current macro "%s"'%\
                                                                                (name[0], macro_name)
                if name[1] in cm_varnames.values():
                    raise Exception, 'Syntax Error reg "%s" already named in current macro "%s"'%\
                                                                                (name[1], macro_name)
                cm_varnames[name[0]] = name[1]
                if macro_name in local_macros:
                    local_macros[macro_name].append('#' + line)
                elif macro_name in global_macros:
                    global_macros[macro_name].append('#' + line)
            else:
                if varnames[-1].has_key(name[0]):
                    raise Exception, \
                    'Syntax Error name "%s" already defined in current scope\n line = "%s"'\
                                                                                   % (name[0], line)
                if name[1] in varnames[-1].values():
                    raise Exception, \
                    'Syntax Error reg "%s" already named in current scope\n line = "%s"'%\
                                                                                (name[1], line)
                varnames[-1][name[0]] = name[1]
                scopes[-1].append('#' + line)
        else:
            if in_macro:
                #check for macro-in-macro
                if macro_name in local_macros.keys():
                    local_macros[macro_name].append(line)
                    #+= rep_line(line, local_macros, use_kernel_macros)
                if macro_name in global_macros.keys():
                    global_macros[macro_name].append(line)
                    #+= rep_line(line, local_macros, use_kernel_macros)
            else:
                #check for regular ol' macro
                scopes[-1] += rep_line(line, local_macros, use_kernel_macros) * repetitions
                repetitions = 1
    if len(scopes) == 1 and len(varnames) == 1:
        lines = rep_names(scopes[0], varnames[0])
        for i, line in enumerate(lines):
            atsign = line.find('@')
            hashsign = line.find('#')
            if toplevel and atsign != -1 and (atsign < hashsign or hashsign == -1):
                raise Warning, "Syntax error name unconverted on line = '%s'" % line
            if toplevel and line and line[-1] == '>': lines[i] = line[:-1]
            lines[i] = ' '*4 + lines[i].lstrip().rstrip()
        if strip_comments:
            return '\n'.join([l for l in lines if not l.strip().startswith('#') and l.strip() != ''])
        else:
            return '\n'.join(lines)
        
    else:
        raise Exception, "Scoping Error"

def process(path, out, kernel=False, replace_labels=False, use_kernel_macros=False, cstrip=False, first=0, ps=[]):
    global global_macros, strip_comments, first_prog, magic_strings #magic!
    magic_strings = ps
    strip_comments = cstrip
    first_prog = first
    
    f1 = open(path, 'r')
    s = get_file_text(f1)
    if replace_labels:
        s = substitute_labels(s)
    s = process_lines(s, kernel, use_kernel_macros, toplevel=True)
    
    f1.close()
    #write giant string to file
    f2 = open(out, 'w')
    f2.write(s)
    f2.close()
    
    #make_kernel_macros()
    #print kernel_macros['load_user_programs']
    #print main_labels
    #print global_macros

if __name__ == "__main__":
    #if called from the cl, process with default args
    try:
        infile = sys.argv[1]
        outfile = sys.argv[2]
    except:
        raise Exception, "use 'python mpp.py in_file out_file"
    
    process(infile, outfile)
