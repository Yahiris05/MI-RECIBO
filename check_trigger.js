import pg from 'pg';
const { Client } = pg;

const connectionString = "postgresql://postgres.hmrbudrmzwyzbrywzywb:YAHIRIS05'S@aws-0-us-east-2.pooler.supabase.com:6543/postgres";

async function main() {
  const client = new Client({ connectionString });
  try {
    await client.connect();
    console.log("Connected to remote database successfully!");

    // Check profiles structure
    const cols = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'profiles';
    `);
    console.log("Profiles columns:", cols.rows);

    // Check triggers
    const triggers = await client.query(`
      SELECT trigger_name, event_manipulation, event_object_table, action_statement
      FROM information_schema.triggers;
    `);
    console.log("Triggers:", triggers.rows.filter(t => t.event_object_table === 'users'));

    // Check if there are any error logs or let's try to see if public.profiles exists and its RLS policies
    const policies = await client.query(`
      SELECT * FROM pg_policies WHERE tablename = 'profiles';
    `);
    console.log("Policies on profiles:", policies.rows);

  } catch (err) {
    console.error("Error:", err);
  } finally {
    await client.end();
  }
}

main();
