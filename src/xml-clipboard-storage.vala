/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;

namespace Diodon
{
    /**
     * Xml clipboard storage implementation using
     * libxml2 to store parse and write the xml file.
     * Xml will always be flushed after storage has changed.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class XmlClipboardStorage : GLib.Object, IClipboardStorage
    {
        private ArrayList<ClipboardItem> items;
        private string xml_file;
    
        /**
         * Xml file constructor.
         * 
         * @param directory directory file is located
         * @param file xml file name
         */
        public XmlClipboardStorage(string directory, string file)
        {
            items = new ArrayList<ClipboardItem>((GLib.EqualFunc?)ClipboardItem.equal_func);
            
            // make sure that all parent directories exists
            try {
                File dir = File.new_for_path(directory);
                if(!dir.query_exists(null)) {
                    dir.make_directory_with_parents(null);
                }
            } catch (Error e) {
                warning ("could not create directory %s", directory);
            }
            
            xml_file = Path.build_filename(directory, file);
            load();
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void remove_item(ClipboardItem item)
        {
            items.remove(item);
            write();
        }
        
        /**
	     * {@inheritDoc}
	     */
        public ArrayList<ClipboardItem> get_items()
        {
            return items;
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void add_item(ClipboardItem item)
        {
            items.add(item);
            write();
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void clear()
        {
            items.clear();
            write();
        }
        
        /**
         * Load storage xml to memory
         */
        public void load()
        {   
            debug("Read storage file " + xml_file);
            Xml.TextReader reader = new Xml.TextReader.filename(xml_file);
            
            while(reader.read() == 1) {
                // import node when it is a item element
                if("item" == reader.name() && reader.node_type() == 1) {
                    string value = reader.read_string();
                    if(value != null) {
                        debug("Add item " + value + " to clipboard.");
                        ClipboardItem item = new ClipboardItem(ClipboardType.NONE, value);
                        items.add(item);
                    }
                }    
            }
        }
        
        /**
         * Write storage to xml file
         */
        public void write()
        {
            Xml.TextWriter writer = new Xml.TextWriter.filename(xml_file);
            writer.set_indent(true);
            writer.set_indent_string ("\t");

            writer.start_document ();
            writer.start_element ("clipboard");
            
            foreach(ClipboardItem item in items) {
                writer.write_element("item", item.text);
            }
            
            writer.end_element();
            writer.end_document();
            
            writer.flush();
        }
    }  
}
 
